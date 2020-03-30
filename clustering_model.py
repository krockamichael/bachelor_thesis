import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from keras.models import load_model
from keras import Model
from utils import loadFile, ClusteringLayer
import sys
import numpy as np

# so that numpy prints the whole array
np.set_printoptions(threshold=sys.maxsize)

# load model
autoencoder = load_model('models/LSTM_100_mask_epochs_300_BS_256_acc_87.86989450454712.h5')

# get encoder part + clustering_layer = model
encoder = Model(input=autoencoder.layers[0].input, output=autoencoder.layers[2].output)
clustering_layer = ClusteringLayer(n_clusters, name='clustering')(encoder.output)
model = Model(inputs=encoder.input, outputs=clustering_layer)
model.compile(optimizer='adam', loss='mse', metrics=['accuracy'])
print(model.summary())

# load data
context_paths = loadFile()
print('Loaded data.')


