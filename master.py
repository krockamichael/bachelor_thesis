import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from keras.layers import LSTM, RepeatVector, TimeDistributed, Dense, Masking, Input, Lambda
from utils import loadFile, doGraphsAutoencoder_v2, TimingCallback, getModelName, cropOutputs, getLastEncoderLayer, \
    target_distribution, print_to_file
from ClusteringLayer import ClusteringLayer
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

"""
test 1:
    - encoder layers non-trainable
    - 1 LSTM layer
    - regularizers.l1(10e-5)
    - 128 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- only used 2 categories - trash
    
test 2:
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5) on 2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- autoencoder converged sLoWlY
    
test 3:
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5) on 1st LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- only used 2 categories -- trash
    
test 4:
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        1st & 2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- autoencoder converges (?) SLOWLY
           -- same max percentage number for every label
           -- cluster is trash

test 5:
    - encoder layers TRAINABLE
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        1st LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 128 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- high loss on 1st epoch
           -- autoencoder converges slowly
           -- clustering decides based on AST size
           -- trash

test 6:
    - encoder layers non-trainable
    - 3 LSTM layers
    - regularizers.l1(10e-5):
        1st LSTM layer
    - 128 neurons, 64 neurons, 10 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- high loss on 1st epoch
           -- loss was going down, but slowly
           -- accuracy at a ~standstill
           -- used 5 / 7 labels
           -- reached tolerance threshold
           -- clustering decides based on AST size
           -- trash

test 7:
    - NEWEST DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 200 epochs
    - 128 batch size autoencoder
    - 10 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- used only 3 categories
           -- trash
           
test 8:
    - ONLY BIG DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 10 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- used only 2 categories
           -- trash

test 9:
    - MASKING_VALUE = [0, 0, 0]
    - everything DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 10 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- used only 7 / 10 categories, and not well
           -- problem with 10 categories??
           -- trash
           
test 10:
    - MASKING_VALUE = 0
    - everything DATASET
    - encoder layers non-trainable
    - 2 LSTM layers
    - dropout(0.2):
        1st LSTM layer
    - regularizers.l1(10e-5):
        2nd LSTM layer
    - 128 neurons, 64 neurons
    - 20 epochs
    - 128 batch size autoencoder
    - 7 clusters
    - 256 batch size clustering
    - 0.001 tolerance
    - 8000 maximum iterations
    RESULT -- only used 2 categories
           -- trash
           
test 11:
    - same as 2, retraining clutering layer just to see
    RESULT -- worked well
           -- autoencoder setup from 2 is good - let's try to make it better
    
test 12:
    - same as 2, without masking
    RESULT -- masking is important
           -- only used 2 categories
           -- trash
           
test 13:
    - same as 2, with mask_value=[0, 0, 0]
    RESULT -- trash
    
test 14:
    - same as 2, with dropout
    - dropout 0.2 on LSTM layer 2
    RESULT -- trash
           -- used only 3 categories
           
test 15:
    - same as 2, with dropout 0.2 on LSTM layer 1
    RESULT -- used only 5 categories, with 2 being below 50 members
           -- trash
           
test 16:
    - same as 2, regularizers.l1(10e-4) from 10e-5
    RESULT -- used only 5 categories, with 3 being below 300 members
           -- trash

test 17:
    - same as 2, regularizers.l1(10e-3) from 10e-5
    RESULT -- used only 1 categorie
           -- trash

test 18:
    - same as 2, regularizers.l1(10e-6) from 10e-5
    RESULT -- used 4 / 7 categories, wasn't THAT bad looked ok
           -- check it in BP-visualisation

test 19:
    - 1 LSTM - 16
    RESULT - promising
           - used all categories
           - used one categorie poorly
           - used all 8000 iterations for clustering
           - check in BP-visualisation

test 20:
    - 1 LSTM - 8
    RESULT - same as 16
           - graph warning because of no variance between some labels
           - used 4200 iterations for clustering
           
test 21:
    - 2 LSTM - 16, 8
    RESULT - promising results
           - used 3360 iterations for clustering
           - check in BP-visualisation
           -- ALERT -- first layer in decoder had 64 (instead of 8) by mistake
           
test 22:
    - 2 LSTM - 16, 8 - but with correct first layer in decoder
    RESULT - promising results
           - label 0 and label 4 showed linear correlation
           - checked in BP visualisation - no noticeable patterns
           - subject to closer inspection
           
MIDWAY CONCLUSION - test 2 looks (in BP visualisation) to be the most promising
                  - data samples in categories have something in common, for sure
                  - what is it in detail?
                  - some samples have clear connections between them - structure, order, node types
                  - but those same samples can have no connection whatsoever with other samples in the same label
                  RESULT -- try MORE labels - 10~ and go from there
                  
test 23:
    - same as 2
    - 10 labels (instead of 7)
    RESULT -- trash
    
test 24:
    - same as 2
    - 6 labels (instead of 7)
    RESULT -- trash
    
test 25:
    - same as 2
    - 6 labels
    - loaded autoencoder from 2
    RESULT -- used the categories "well" - one has only 186 members others are acceptable
    
test 26:
    - same as 2
    - 10 labels
    RESULT -- used only 8 / 10 categories
           -- could be better
    
test 27:
    - autoencoder from 2
    - 32000 max iterations
    - 20 labels
    RESULT -- trash
    
test 28:
    - 3 LSTM layers
    - 128, 64, 32
    - regularizer.l1(10e-5) on 3rd layer
    RESULT -- trash
    
test 29:
    - 4 LSTM layers
    - 128, 64, 32, 16
    - regularizer.l1(10e-5) on 2nd and 4th layer
    RESULT -- trash
    
test 30:
    - 3 LSTM
    - 128, 64, 32
    - regularizers.l1(10e-5) on 2nd
    - regularizers.l1(10e-3) on 3rd
    RESULT -- trash
    
test 31:
    - 3 LSTM
    - 128, 64, 32
    - regularizers.l1(10e-5) on 2nd
    RESULT -- trash
    
test 32:
    - loaded autoencoder from 2
    - 8 labels
    RESULT -- okay
    
test 33:
    - laoded autoencoder from 2
    - 9 labels
    RESULT -- trash
    
test 34:
    - master autoencoder
    - 7 lables
    - adam optimizer in clustering model
    RESULT -- trash

test 35:
    - master autoencoder
    - 7 labels
    - SGD(0.01, 0.9) optimizer in clustering model
    - tol == 0.001
    RESULT -- 6 / 7 labels
    
test 36:
    - master autoencoder
    - 6 labels
    - SGD(0.01, 0.9) optimizer in clustering model
    - tol == 0.0015
    RESULT -- used 4 / 6 categories
           -- used a 5th category but only 8 members
           -- trash
           
test 37:
    - autoencoder setup from test 2
    - correct_dataset
    - 7 labels
    - tol == 0.001
    RESULT -- is ok
    
test 38:
    - autoencoder from 37
    - 10 labels
    RESULT -- okay
    
test 39:
    - autoencoder from 37
    - 20 labels
    RESULT -- okay
    
test 30:
    - autoencoder from 37
    - 50 labels
    RESULT -- 
"""


# lower regularizer value should incline the representation to be differentiated based on AST size
# TODO if 3 LSTM layers produce good results, try to match n_clusters with the number of neurons in the last LSTM layer - or the other way around

# FIXME
destination_folder = 'testing/test_40/'
try:
    os.mkdir(destination_folder)
except OSError as exc:
    if exc.errno != errno.EEXIST:
        raise
    pass

LSTM_num = 2
neurons = 128
epochs = 20
batch_size_auto = 128
n_clusters = 50
batch_size_clust = 256
maxiter = 8000
tol = 0.001
# FIXME

# Create a readme file for each test, training data is appended after clustering model is trained
read_me_filename = destination_folder + 'readme.md'
with open(read_me_filename, 'w+') as f:
    f.write('encoder layers: {}\n'.format('non-trainable'))
    f.write('LSTM: {}\n'.format(LSTM_num))
    f.write('neurons_1: {}\n'.format(neurons))
    f.write('neurons_2: {}\n'.format(neurons / 2))
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
# AUTOENCODER
# inputs = Input(shape=(430, 3))
# masked_input = Masking(mask_value=0, input_shape=(430, 3))(inputs)
# encoded = LSTM(neurons, return_sequences=True)(masked_input)
# encoded = LSTM(64, return_sequences=False, activity_regularizer=regularizers.l1(10e-5))(encoded)
# decoded = RepeatVector(430)(encoded)
# decoded = LSTM(64, return_sequences=True)(decoded)
# decoded = LSTM(neurons, return_sequences=True)(decoded)
# decoded = TimeDistributed(Dense(3))(decoded)
# decoded = Lambda(cropOutputs, output_shape=(430, 3))([decoded, inputs])
# autoencoder = Model(inputs=inputs, outputs=decoded, name='autoencoder')
# autoencoder.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
# print(autoencoder.summary())
#
# # print autoencoder summary to file
# autoencoder_summary_filename = destination_folder + 'autoencoder_summary.md'
# with open(autoencoder_summary_filename, 'w+') as fh:
#     autoencoder.summary(print_fn=lambda row: fh.write(row + '\n'))

# load data and split into train, validate and test (70, 20, 10)
names, context_paths = loadFile('data/correct_dataset.csv')
train, validate, test = np.split(context_paths, [int(.7*len(context_paths)), int(.9*len(context_paths))])
print('Loaded data.')
#
# # start training autoencoder model
# cb = TimingCallback()
# history = autoencoder.fit(train, train, epochs=epochs, batch_size=batch_size_auto, verbose=2, shuffle=True, validation_data=(validate, validate), callbacks=[cb])
# # print(cb.logs)
# print('Total training time of autoencoder: {}'.format(sum(cb.logs)))
# with open(read_me_filename, 'a+') as f:
#     f.write('Autoencoder training time: {}\n'.format(sum(cb.logs)))
#
# # evaluate model on test data that wasn't used during training
# print('Evaluating model on test data...')
# score = autoencoder.evaluate(test, test, verbose=0)
# print("%s: %.2f%%" % (autoencoder.metrics_names[1], score[1]*100))
# print("%s: %.2f%%" % (autoencoder.metrics_names[0], score[0]*100))
#
# # save autoencoder model to file
# autoencoder_name = getModelName(autoencoder, neurons, epochs, batch_size_auto, score[1]*100)
# autoencoder.save(destination_folder + autoencoder_name.replace('models/', ''))
# print("Saved autoencoder model.\n\n\n")
#
# # create graphs for model loss and accuracy & save them
# doGraphsAutoencoder_v2(history, destination_folder)

autoencoder = load_model('testing/test_37/LSTM_128_mask_epochs_20_BS_128_acc_81.95578455924988.h5')


# ----------------------------------------------------------------------------------------------------------------------
# CLUSTERING_MODEL
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
kmeans = KMeans(n_clusters=n_clusters, n_init=20)  # TODO try different n_init
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

        # check stop criterion - model convergence
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
sns.set(style='ticks')
sns.pairplot(df, hue=n_clusters)
plt.savefig(destination_folder + str(n_clusters) + '_predictions.png')
plt.show()
