import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from sklearn.cluster import KMeans
from utils import loadFile, getClusteringModel_andEncoder, doGraphsClustering

n_clusters = 9

# load clustering model and encoder
model, encoder = getClusteringModel_andEncoder(n_clusters, train=False)
print(model.summary())

# load data
context_paths = loadFile()
print('Loaded data.')

# init cluster centers using k-means
kmeans = KMeans(n_clusters=n_clusters, n_init=20, random_state=1)

print('Clustering model predicting...')
x_model = model.predict(context_paths, verbose=1)
print('Predicting clustering model labels...')
y_model = kmeans.fit_predict(x_model)

print('Encoder model predicting...')
x_encoder = encoder.predict(context_paths, verbose=1)
print('Predicting encoder model labels...')
y_encoder = kmeans.fit_predict(x_encoder)

doGraphsClustering(n_clusters, x_model, y_model, x_encoder, y_encoder)
print('Saved graphs.')
