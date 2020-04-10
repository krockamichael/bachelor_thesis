import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from utils import loadFile, getClusteringModel_andEncoder, doGraphsClustering
from sklearn.cluster import KMeans
from keras.models import load_model
import numpy as np
import sys


def testClustering():
    n_clusters = 7
    batch_size = 256

    # load clustering model and encoder
    model, encoder = getClusteringModel_andEncoder(n_clusters, batch_size, train=False)
    print(model.summary())

    # load file names and data
    names, context_paths = loadFile()
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

    doGraphsClustering(n_clusters, batch_size, x_model, y_model, x_encoder, y_encoder)
    print('Saved graphs.')


def testAutoencoder():
    np.set_printoptions(threshold=sys.maxsize)

    # load data
    names, data = loadFile()

    # load model
    autoencoder = load_model('models\LSTM_128_mask_epochs_300_BS_128_acc_89.04606699943542.h5')

    print('Evaluating model...')
    # score = autoencoder.evaluate(data, data, verbose=1)
    # print("%s: %.2f%%" % (autoencoder.metrics_names[1], score[1] * 100))
    # print("%s: %.2f%%" % (autoencoder.metrics_names[0], score[0] * 100))

    # predict a data sample
    predict_sample = data[0].reshape((1, 430, 3))
    predict_output = autoencoder.predict(predict_sample, verbose=0)
    # print(predict_sample[0])
    # print(predict_output[0])

    # prints rows side by side, first three values are original, second three values are predicted
    print(np.c_[predict_sample[0], predict_output[0]])


if __name__ == '__main__':
    print('Press 1 for clustering, 2 for autoencoder.')
    if input() == '1':
        print('Testing clustering.')
        testClustering()
    elif input() == '2':
        print('Testing autoencoder.')
        testAutoencoder()
