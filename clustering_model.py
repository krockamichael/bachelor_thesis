import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from keras.models import load_model
from keras.optimizers import SGD
from keras import Model
from utils import loadFile, ClusteringLayer, getClusteringModelName, target_distribution, getClusteringModel_andEncoder
from sklearn.cluster import KMeans
import numpy as np

n_clusters = 9  # as a start 10, 11, 12, 13
batch_size = 256

# load data
context_paths = loadFile()
print('Loaded data.')

# load model
model, encoder = getClusteringModel_andEncoder(n_clusters, train=True)
print(model.summary())

# init cluster centers using k-means
kmeans = KMeans(n_clusters=n_clusters, n_init=20)
print('Predicting "labels"...')
y_pred = kmeans.fit_predict(encoder.predict(context_paths))
y_pred_last = np.copy(y_pred)  # ???
model.get_layer(name='clustering').set_weights([kmeans.cluster_centers_])


loss = 0
index = 0
maxiter = 8000
update_interval = 140
index_array = np.arange(context_paths.shape[0])

tol = 0.001  # tolerance threshold to stop training

# start training
print('Starting training...')
for ite in range(int(maxiter)):
    if ite % update_interval == 0:
        print('Iteration {}'.format(ite))
        q = model.predict(context_paths, verbose=1)
        p = target_distribution(q)  # update the auxiliary target distribution p

        # evaluate the clustering performance
        y_pred = q.argmax(1)
        # if y is not None:
        #     acc = np.round(metrics.acc(y, y_pred), 5)
        #     nmi = np.round(metrics.nmi(y, y_pred), 5)
        #     ari = np.round(metrics.ari(y, y_pred), 5)
        #     loss = np.round(loss, 5)
        #     print('Iter %d: acc = %.5f, nmi = %.5f, ari = %.5f' % (ite, acc, nmi, ari), ' ; loss=', loss)

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

model.save_weights('clustering_weights/' + getClusteringModelName(n_clusters))
