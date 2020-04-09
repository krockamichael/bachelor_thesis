# bachelor_thesis
Keras neural network - LSTM autoencoder, clustering model

autoencoder.py - source code for the autoencoder model consisting of: masking - lstm - repeatVector - lstm - timeDistributed(dense) - lambda(cropOutputs) layers

clustering_model.py - encoder + clustering layer

utils.py - helpful functions for loading dataset, generating and saving graphs, creating model names, custom callback function

clustering_weights - contain trained clustering models named to represent the number of clusters present

models / graphs - named in the sense of most notable layer (LSTM) followed by number of neurons in said layer, may contain a 'mask' layer, the number of epochs_X it was trained for with batch size BS_Y and finally the accuracy of the model acc_Z

X, Y, Z are numbers