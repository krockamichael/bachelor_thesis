import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from utils import loadFile, target_distribution, getClusteringModel_andEncoder, doGraphsClustering, \
    getClusteringModelName
from sklearn.cluster import KMeans
import numpy as np
import time

""" WARNING - training a new model with the same parameters overwrites the old model """
# configure these parameters to train a model
n_clusters = 7
batch_size = 256  # upon CHANGE: values remain almost the same, only label numbers are shuffled

# load file names and data
names, context_paths = loadFile()
print('Loaded data.')

# load model
model, encoder = getClusteringModel_andEncoder(n_clusters, batch_size, train=True)
print(model.summary())

# init cluster centers using k-means
kmeans = KMeans(n_clusters=n_clusters, n_init=20, random_state=2)
print('Predicting "labels"...')
y_pred = kmeans.fit_predict(encoder.predict(context_paths))
y_pred_last = np.copy(y_pred)  # ???
model.get_layer(name='clustering').set_weights([kmeans.cluster_centers_])


loss = 0
index = 0
maxiter = 8000
update_interval = 140  # upon CHANGE: values remain almost the same, only label numbers are shuffled
index_array = np.arange(context_paths.shape[0])
tol = 0.001  # tolerance threshold to stop training, upon CHANGE: tried lowering to 0.0001 --> no noticeable difference

# start training
start_time = time.time()
print('Starting training...')
for ite in range(int(maxiter)):
    if ite % update_interval == 0:
        print('Iteration {}\nLoss {}'.format(ite, loss))
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

model.save_weights('clustering_weights/' + getClusteringModelName(n_clusters, batch_size))
print('Elapsed time: {}'.format(time.time() - start_time))

# init cluster centers using k-means
kmeans_for_graphs = KMeans(n_clusters=n_clusters, n_init=20, random_state=1)

print('Clustering model predicting...')
x_model = model.predict(context_paths, verbose=1)
print('Predicting clustering model labels...')
y_model = kmeans_for_graphs.fit_predict(x_model)

print('Encoder model predicting...')
x_encoder = encoder.predict(context_paths, verbose=1)
print('Predicting encoder model labels...')
y_encoder = kmeans_for_graphs.fit_predict(x_encoder)

doGraphsClustering(n_clusters, batch_size, x_model, y_model, x_encoder, y_encoder)
print('Saved graphs.')
