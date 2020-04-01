import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from sklearn.cluster import KMeans
from utils import loadFile, getClusteringModel_andEncoder
from sklearn.metrics import confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

n_clusters = 11

# load clustering model and encoder
model, encoder = getClusteringModel_andEncoder(n_clusters)
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

# create scatterplot from labels assigned to data predicted by CLUSTERING model
plt.figure(figsize=(6, 6))
plt.scatter(x_model[:, 0], x_model[:, 1], c=y_model)
plt.colorbar()
plt.title('Scatterplot - clustering')
plt.show()

# create scatterplot from labels assigned to data predicted by ENCODER model
plt.figure(figsize=(6, 6))
plt.scatter(x_encoder[:, 0], x_encoder[:, 1], c=y_encoder)
plt.colorbar()
plt.title('Scatterplot - encoder')
plt.show()

# create confusion matrix from predictions based on data predicted by clustering and encoder models
sns.set(font_scale=3)
confusion_matrix = confusion_matrix(y_encoder, y_model)
plt.figure(figsize=(16, 14))
sns.heatmap(confusion_matrix, annot=True, fmt="d", annot_kws={"size": 20})
plt.title("Confusion matrix", fontsize=30)
plt.ylabel('Encoder label', fontsize=25)
plt.xlabel('Clustering label', fontsize=25)
plt.show()
