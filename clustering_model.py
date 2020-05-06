import csv
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from utils import loadFile, target_distribution, getClusteringModel_andEncoder, getClusteringModelName
from sklearn.cluster import KMeans
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
import time

""" WARNING - training a new model with the same parameters overwrites the old model """
# configure these parameters to train a model
n_clusters = 7
batch_size = 256  # upon CHANGE: for 7~ clusters values remain almost the same, for 10+ clusters big diff

# load file names and data
names, context_paths = loadFile()
print('Loaded data.')

# load model
model, encoder = getClusteringModel_andEncoder(n_clusters, batch_size, train=True, LSTM=3)
print(model.summary())

# init cluster centers using k-means
kmeans = KMeans(n_clusters=n_clusters, n_init=20)
print('Predicting "labels"...')
y_pred = kmeans.fit_predict(encoder.predict(context_paths))
y_pred_last = np.copy(y_pred)
model.get_layer(name='clustering').set_weights([kmeans.cluster_centers_])

loss = 0
index = 0
maxiter = 8000
update_interval = 140  # upon CHANGE: values remain almost the same, only label numbers are shuffled
index_array = np.arange(context_paths.shape[0])
tol = 0.0001  # tolerance threshold to stop training, upon CHANGE: tried lowering to 0.0001 --> no noticeable difference

# start training
start_time = time.time()
print('Starting training...')
for ite in range(int(maxiter)):
    if ite % update_interval == 0:
        if ite > 0:
            print('Iteration {}\nLoss {:f}\nDelta Label {:f}\n'.format(ite, loss, delta_label))
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
    idx = index_array[index * batch_size: min((index+1) * batch_size, context_paths.shape[0])]
    loss = model.train_on_batch(x=context_paths[idx], y=p[idx])
    index = index + 1 if (index + 1) * batch_size <= context_paths.shape[0] else 0

model.save_weights('temp.h5')  # + getClusteringModelName(model, n_clusters, batch_size))
print('Elapsed time: {}'.format(time.time() - start_time))

x_model = model.predict(context_paths, verbose=1)
y_model = x_model.argmax(1)

# filename = getPredictionsCSVName(model_name)
filename = 'temp.csv'
with open(filename, 'w', newline='') as file:
    thewriter = csv.writer(file)
    for x, y in zip(x_model, y_model):
        thewriter.writerow([str(x[0]), str(x[1]), str(x[2]), str(x[3]), str(x[4]), str(x[5]), str(x[6]), str(y)])
file.close()

df = pd.read_csv('temp.csv', delimiter=',', header=None)
sns.set(style='ticks')
sns.pairplot(df, hue=7)
plt.savefig('temp_predictions.png')
plt.show()

# testClustering(n_clusters, batch_size, encoder, model, names, context_paths)
