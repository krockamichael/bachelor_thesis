from ClusteringLayer import ClusteringLayer
from sklearn.metrics import confusion_matrix
from keras.models import load_model, Model
from timeit import default_timer as timer
from keras.callbacks import Callback
from keras.optimizers import SGD
import matplotlib.pyplot as plt
from keras import backend as K
import seaborn as sns
import pandas as pd
import numpy as np
import errno
import os
import csv
import sys


def print_to_file(filename, message):
    old_std_out = sys.stdout
    sys.stdout = open(filename, 'a+')
    print(message)
    sys.stdout.close()
    sys.stdout = old_std_out


# computing an auxiliary target distribution
def target_distribution(q_):
    weight = q_ ** 2 / q_.sum(0)
    return (weight.T / weight.sum(1)).T


def getLastEncoderLayer(layers):
    for index, layer in enumerate(layers):
        if layer.name == 'repeat_vector_1':
            return index - 1


def getClusteringModel_andEncoder(n_clusters, batch_size, train, LSTM):
    # load autoencoder model
    autoencoder = load_model('XDDD/LSTM_128_mask_epochs_10_BS_128_acc_81.62408471107483.h5')
    # autoencoder = load_model('models\LSTM_' + str(LSTM) + '_best_autoencoder_83.h5')
    output_layer_index = getLastEncoderLayer(autoencoder.layers)

    # get only encoder part
    encoder = Model(inputs=autoencoder.layers[0].input, outputs=autoencoder.layers[output_layer_index].output, name='encoder')
    for layer in encoder.layers:
        layer.trainable = False
    clustering_layer = ClusteringLayer(n_clusters, name='clustering')(encoder.output)
    model = Model(inputs=encoder.input, outputs=clustering_layer, name='clustering_model')
    if not train:
        model.load_weights('XDDD/temp.h5')
        # model.load_weights('clustering_weights/' + getClusteringModelName(model, n_clusters, batch_size))
    model.compile(optimizer=SGD(0.01, 0.9), loss='kld')

    return model, encoder


class TimingCallback(Callback):
    def __init__(self, logs={}):
        self.logs = []

    def on_epoch_begin(self, epoch, logs={}):
        self.starttime = timer()

    def on_epoch_end(self, epoch, logs={}):
        self.logs.append(timer() - self.starttime)


def cropOutputs(x):
    # x[0] is decoded at the end
    # x[1] is inputs
    # both have the same shape

    # padding = 1 for actual data in inputs, 0 for 0
    padding = K.cast(K.not_equal(x[1], 0), dtype=K.floatx())
    # if you have zeros for non-padded data, they will lose their backpropagation

    return x[0] * padding


def getLSTMNumbers(model):
    count = 0
    for layer in model.layers:
        if 'lstm' in layer.name:
            count += 1
    return str(count)


def getClusteringModelName(model, n_clusters, batch_size):
    return 'LSTM_' + getLSTMNumbers(model) + '_clusters_' + str(n_clusters) + '_bs_' + str(batch_size) + '.h5'


def getModelName(model, neurons, epochs, batch_size, acc):
    model_name = 'models/'
    pos = 0
    if model.layers[0].name == 'input_1':
        pos = 1

    if model.layers[pos].name == 'masking_1':
        if model.layers[pos + 1].name == 'lstm_1':
            model_name += 'LSTM_' + str(neurons) + '_mask'
        elif model.layers[pos + 1].name == 'dense_1':
            model_name += 'Dense_' + str(neurons) + '_mask'
    elif model.layers[pos].name == 'lstm_1':
        model_name += 'LSTM_' + str(neurons)
    elif model.layers[pos].name == 'dense_1':
        model_name += 'Dense_' + str(neurons)
    model_name += '_epochs_' + str(epochs)
    model_name += '_BS_' + str(batch_size)
    model_name += '_acc_' + str(acc) + '.h5'

    return model_name


def getPredictionsCSVName(model_name):
    return 'clustering_weights/' + model_name.replace('.h5', '') + '_predictions.csv'


def savePredictions(x_model, y_model, model_name):
    # filename = getPredictionsCSVName(model_name)
    filename = 'temp.csv'
    with open(filename, 'w', newline='') as file:
        thewriter = csv.writer(file)
        for x, y in zip(x_model, y_model):
            thewriter.writerow([str(x[0]), str(x[1]), str(x[2]), str(x[3]), str(x[4]), str(x[5]), str(x[6]), str(y)])
    file.close()


def loadFile(path=None):
    if path is not None:
        with open(path, 'r') as file:
            lines = file.readlines()
        file.close()
    else:
        with open('data/correct_dataset.csv', 'r') as file:
            lines = file.readlines()
        file.close()

    print('Processing input file...')
    triplets = [l.replace('"', '').replace('\n', '').split(" ") for l in lines]  # (18000, 430)
    singles = []  # (18000, 430, 3)
    for t in triplets:
        singles += [[trp.split(',') for trp in t]]

    names = []  # get file name
    for single in singles:
        names += single[0]
        single.remove(single[0])

    data = np.ma.array(singles).astype(np.int32)
    masked_data = np.ma.masked_equal(data, 0)  # values without zero-padding

    # normalise data
    print('Normalising data...')
    # DATASET masked_data.mean() == -120.57979590730959
    # DATASET masked_data.std() == 1115300671.9887397
    # no_duplicates_DATASET masked_data.mean() == 1015.0810487060508
    # no_duplicates_DATASET masked_data.std() == 1108213954.9788578
    normalised_masked_data = (masked_data - masked_data.mean()) / masked_data.std()  # perform z-normalisation
    final_data = normalised_masked_data.filled(0)  # refill masked values with 0
    # final_data.max()  ==  1.9242677998256246
    # final_data.min()  == -1.9236537371711413
    # final_data.std()  ==  0.5883442183749463
    # final_data.mean() == -0.0440249105206687

    return names, final_data


def doGraphsAutoencoder(history, model_name):
    # summarize history for accuracy
    plt.plot(history.history['accuracy'])
    plt.plot(history.history['val_accuracy'])
    plt.title('model accuracy')
    plt.ylabel('accuracy')
    plt.xlabel('epoch')
    plt.legend(['train', 'test'], loc='upper left')
    plt.savefig(model_name.replace('.h5', '_accuracy.png').replace('models/', 'graphs/autoencoder/'))
    plt.show()

    # summarize history for loss
    plt.plot(history.history['loss'])
    plt.plot(history.history['val_loss'])
    plt.title('model loss')
    plt.ylabel('loss')
    plt.xlabel('epoch')
    plt.legend(['train', 'test'], loc='upper left')
    plt.savefig(model_name.replace('.h5', '_loss.png').replace('models/', 'graphs/autoencoder/'))
    plt.show()


def doGraphsAutoencoder_v2(history, destination_folder):
    # summarize history for accuracy
    plt.plot(history.history['accuracy'])
    plt.plot(history.history['val_accuracy'])
    plt.title('model accuracy')
    plt.ylabel('accuracy')
    plt.xlabel('epoch')
    plt.legend(['train', 'test'], loc='upper left')
    plt.savefig(destination_folder + 'autoencoder_accuracy.png')
    plt.show()

    # summarize history for loss
    plt.plot(history.history['loss'])
    plt.plot(history.history['val_loss'])
    plt.title('model loss')
    plt.ylabel('loss')
    plt.xlabel('epoch')
    plt.legend(['train', 'test'], loc='upper left')
    plt.savefig(destination_folder + 'autoencoder_loss.png')
    plt.show()


def doGraphsClustering(model, n_clusters, batch_size, x_model, y_model, x_encoder, y_encoder):
    path = 'graphs/clustering/' + getClusteringModelName(model, n_clusters, batch_size).replace('.h5', '')
    try:
        os.mkdir(path)
    except OSError as exc:
        if exc.errno != errno.EEXIST:
            raise
        pass

    # create scatterplot from labels assigned to data predicted by CLUSTERING model
    # doClusteringScatterplot(n_clusters, path, x_model, y_model)

    # create scatterplot from labels assigned to data predicted by ENCODER model
    # plt.figure(figsize=(6, 6))
    # plt.scatter(x_encoder[:, 0], x_encoder[:, 1], c=y_encoder)
    # plt.colorbar()
    # plt.title('Scatterplot - encoder')
    # plt.xlabel('Label 0')
    # plt.ylabel('Label 1')
    # plt.savefig(path + '/scatter_enc_' + str(n_clusters) + '.png')
    # plt.show()
    #
    # pred_file = getPredictionsCSVName(getClusteringModelName(model, n_clusters, batch_size))
    # df = pd.read_csv(pred_file, delimiter=',', header=None)
    # sns.set(style='ticks')
    # sns.pairplot(df, hue=7)
    # plt.savefig(path + '/all_scatterplots_' + str(n_clusters) + '_predictions.png')
    # plt.show()

    # create confusion matrix from predictions based on data predicted by clustering and encoder models
    sns.set(font_scale=3)
    conf_matrix = confusion_matrix(y_encoder, y_model)
    plt.figure(figsize=(16, 14))
    sns.heatmap(conf_matrix, annot=True, fmt='d', annot_kws={'size': 20})
    plt.title('Confusion matrix', fontsize=30)
    plt.ylabel('Encoder label', fontsize=25)
    plt.xlabel('Clustering label', fontsize=25)
    plt.savefig(path + '/conf_m_' + str(n_clusters) + '.png')
    plt.show()


def doClusteringScatterplot(n_clusters, curr_path, x_model, y_model):
    path = curr_path + '/clust_scatterplot'
    try:
        os.mkdir(path)
    except OSError as exc:
        if exc.errno != errno.EEXIST:
            raise
        pass

    x_axis = range(0, n_clusters)
    y_axis = range(0, n_clusters)
    for x in x_axis:
        for y in y_axis:
            if x < y:  # so we don't have duplicate graphs with inverted axes
                plt.figure(figsize=(6, 6))
                plt.scatter(x_model[:, x], x_model[:, y], c=y_model)
                plt.colorbar()
                plt.xlabel('Label ' + str(x))
                plt.ylabel('Label ' + str(y))
                plt.title('Scatterplot - clustering')
                plt.savefig(path + '/label ' + str(x) + '-' + str(y) + '.png')
                plt.show()
