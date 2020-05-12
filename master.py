import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from keras.layers import LSTM, RepeatVector, TimeDistributed, Dense, Masking, Input, Lambda
from utils import loadFile, doGraphsAutoencoder_v2, TimingCallback, getModelName, cropOutputs, \
    getLastEncoderLayer, target_distribution, print_to_file, ClusteringLayer
from sklearn.cluster import KMeans
import matplotlib.pyplot as plt
from keras.models import Model, load_model
from keras.optimizers import SGD
from keras import regularizers
import seaborn as sns
import numpy as np
import pandas as pd
import errno
import time
import csv

# FIXME
# change the test number
test_number = 45

# FIXME
# change parameters of the model
LSTM_num = 2   # no impact, readme file only
units_1 = 128  # dictates the output dimensionality of the first LSMT layer
units_2 = 64   # dictates the output dimensionality of the second LSMT layer
epochs = 20    # number of epochs for which to train autoencoder
batch_size_auto = 128
n_clusters = 10  # number of labels the data will be categorized into
batch_size_clust = 256
maxiter = 8000  # maximum iterations of the clustering model
tol = 0.001  # the tolerance threshold, if this percent of data samples (or less) change label upon update interval, stop
train_autoencoder = True  # if set to False, master autoencoder is loaded


# ----------------------------------------------------------------------------------------------------------------------
# Try to create destination folder
destination_folder = 'testing/test_{}/'.format(test_number)
try:
    os.mkdir(destination_folder)
except OSError as exc:
    if exc.errno != errno.EEXIST:
        raise
    pass

# Create a readme file for each test, training data is appended after clustering model is trained
read_me_filename = destination_folder + 'readme.md'
with open(read_me_filename, 'w+') as f:
    f.write('encoder layers: {}\n'.format('non-trainable'))
    f.write('LSTM: {}\n'.format(LSTM_num))
    f.write('units_1: {}\n'.format(units_1))
    f.write('units_2: {}\n'.format(units_2))
    # f.write('neurons_3: {}\n'.format(neurons / 4))
    f.write('epochs: {}\n'.format(epochs))
    f.write('autoencoder batch_size: {}\n'.format(batch_size_auto))
    f.write('n_clusters: {}\n'.format(n_clusters))
    f.write('clusters batch_size: {}\n'.format(batch_size_clust))
    f.write('max iterations: {}\n'.format(maxiter))
    f.write('tolerance threshold: {}\n'.format(tol))
    f.write('regularizers.l1({}): {}\n'.format('10e-5', 'LSTM layer 2'))
    # f.write('dropout({}): {}\n'.format('0.2', 'LSTM layer 2'))


# ----------------------------------------------------------------------------------------------------------------------
# load data and split into train, validate and test (70, 20, 10)
names, context_paths = loadFile('data/dataset.csv')
train, validate, test = np.split(context_paths, [int(.7*len(context_paths)), int(.9*len(context_paths))])
print('Loaded data.')


# ----------------------------------------------------------------------------------------------------------------------
# AUTOENCODER
if train_autoencoder:
    inputs = Input(shape=(430, 3))
    masked_input = Masking(mask_value=0, input_shape=(430, 3))(inputs)
    encoded = LSTM(units=units_1, return_sequences=True)(masked_input)
    encoded = LSTM(units=units_2, return_sequences=False, activity_regularizer=regularizers.l1(10e-5))(encoded)
    decoded = RepeatVector(430)(encoded)
    decoded = LSTM(units=units_2, return_sequences=True)(decoded)
    decoded = LSTM(units=units_1, return_sequences=True)(decoded)
    decoded = TimeDistributed(Dense(3))(decoded)
    decoded = Lambda(cropOutputs, output_shape=(430, 3))([decoded, inputs])
    autoencoder = Model(inputs=inputs, outputs=decoded, name='autoencoder')
    autoencoder.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
    print(autoencoder.summary())

    # print autoencoder summary to file
    autoencoder_summary_filename = destination_folder + 'autoencoder_summary.md'
    with open(autoencoder_summary_filename, 'w+') as fh:
        autoencoder.summary(print_fn=lambda row: fh.write(row + '\n'))

    # start training autoencoder model
    cb = TimingCallback()
    history = autoencoder.fit(train, train, epochs=epochs, batch_size=batch_size_auto, verbose=2, shuffle=True, validation_data=(validate, validate), callbacks=[cb])
    # print(cb.logs)
    print('Total training time of autoencoder: {}'.format(sum(cb.logs)))
    with open(read_me_filename, 'a+') as f:
        f.write('Autoencoder training time: {}\n'.format(sum(cb.logs)))

    # evaluate model on test data that wasn't used during training
    print('Evaluating model on test data...')
    score = autoencoder.evaluate(test, test, verbose=0)
    print("%s: %.2f%%" % (autoencoder.metrics_names[1], score[1]*100))
    print("%s: %.2f%%" % (autoencoder.metrics_names[0], score[0]*100))

    # save autoencoder model to file
    autoencoder_name = getModelName(autoencoder, units_1, epochs, batch_size_auto, score[1]*100)
    autoencoder.save(destination_folder + autoencoder_name.replace('models/', ''))
    print("Saved autoencoder model.\n\n\n")

    # create graphs for model loss and accuracy & save them
    doGraphsAutoencoder_v2(history, destination_folder)

else:
    # load pre-trained master autoencoder
    autoencoder = load_model('master_autoencoder/master_autoencoder.h5')


# ----------------------------------------------------------------------------------------------------------------------
# CLUSTERING_MODEL
# select only encoder layers from autoencoder and add the clustering layer on top
output_layer_index = getLastEncoderLayer(autoencoder.layers)
encoder = Model(inputs=autoencoder.layers[0].input, outputs=autoencoder.layers[output_layer_index].output, name='encoder')
for layer in encoder.layers:
    layer.trainable = False
clustering_layer = ClusteringLayer(n_clusters, name='clustering')(encoder.output)
model = Model(inputs=encoder.input, outputs=clustering_layer, name='clustering_model')
model.compile(optimizer=SGD(0.01, 0.9), loss='kld')
print(model.summary())

# print clustering model summary to file
model_sum_filename = destination_folder + 'clustering_summary.md'
with open(model_sum_filename, 'w+') as fh:
    model.summary(print_fn=lambda row: fh.write(row + '\n'))

# initialize cluster centers using k-means
print('\nInitializing k-means algorithm to set intial centroids.')
kmeans = KMeans(n_clusters=n_clusters, n_init=20)
y_pred = kmeans.fit_predict(encoder.predict(context_paths))
y_pred_last = np.copy(y_pred)
model.get_layer(name='clustering').set_weights([kmeans.cluster_centers_])

loss = 0
index = 0
update_interval = 140
index_array = np.arange(context_paths.shape[0])

# start training clustering model
start_time = time.time()
print('\nStarting training...')
for ite in range(int(maxiter)):
    if ite % update_interval == 0:
        if ite > 0:
            print('Iteration {}\nLoss {:f}\nDelta Label {:f}\n'.format(ite, loss, delta_label))
            print_to_file(read_me_filename, 'iteration: {}'.format(ite))
            print_to_file(read_me_filename, 'delta_label: {}'.format(delta_label))

        q = model.predict(context_paths)
        p = target_distribution(q)  # update the auxiliary target distribution p

        # evaluate the clustering performance
        y_pred = q.argmax(1)

        # check stop criterion - model convergence, if less than 18
        delta_label = np.sum(y_pred != y_pred_last).astype(np.float32) / y_pred.shape[0]
        y_pred_last = np.copy(y_pred)
        if ite > 0 and delta_label < tol:
            print('delta_label ', delta_label, '< tol ', tol)
            print('Reached tolerance threshold. Stopping training.')
            break
    idx = index_array[index * batch_size_clust: min((index+1) * batch_size_clust, context_paths.shape[0])]
    loss = model.train_on_batch(x=context_paths[idx], y=p[idx])
    index = index + 1 if (index + 1) * batch_size_clust <= context_paths.shape[0] else 0

# save clustering model to file
model.save(destination_folder + 'clustering_model.h5')
print('Total training time of clustering model: {}\n'.format(time.time() - start_time))
with open(read_me_filename, 'a+') as f:
    f.write('Clustering training time: {}\n'.format(time.time() - start_time))


# ----------------------------------------------------------------------------------------------------------------------
# Get data to write in csv files
# x_model - percentages of confidence for each label per data sample
# y_model - final label
print('Clustering model predicting labels...')
x_model = model.predict(context_paths, verbose=0)
y_model = x_model.argmax(1)

# Generate a master csv file with percentages, final labels and ~filenames
filename = destination_folder + 'temp.csv'
with open(filename, 'w', newline='') as file:
    thewriter = csv.writer(file)
    for x, y, name in zip(x_model, y_model, names):
        thewriter.writerow([i for i in x] + [str(y), name])
file.close()

# Load data to a dataframe
# percentages, labels, filenames (~relative paths to from modules/)
df = pd.read_csv(destination_folder + 'temp.csv', delimiter=',', header=None)

# print the maximum percentage of confidence for each label
# print the number of samples per label
print_to_file(read_me_filename, message=df.iloc[:, 0:n_clusters].max())
print_to_file(read_me_filename, message=df[n_clusters].value_counts())
print(df.iloc[:, 0:n_clusters].max())
print(df[n_clusters].value_counts())


# Create csv files with labels as titles
# content is name of data sample (source code file)
name_storage = []
for i in range(0, n_clusters):
    name_storage.append([])
    filename = destination_folder + str(i) + '.csv'
    with open(filename, 'w', newline='') as file:
        thewriter = csv.writer(file)
        for name, label in zip(names, df[n_clusters]):
            if label == i:
                name_storage[i].append(name)
                thewriter.writerow([name])
        file.close()

# create pairplot for predicted labels
print('Creating pairplot...')
df.rename(columns={n_clusters: 'Label'}, inplace=True)
sns.set(style='ticks')
sns.pairplot(df, hue='Label')
plt.savefig(destination_folder + str(n_clusters) + '_predictions.png')
plt.show()
