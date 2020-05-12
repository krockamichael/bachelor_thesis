from keras.engine import InputSpec, Layer
from timeit import default_timer as timer
from keras.callbacks import Callback
import matplotlib.pyplot as plt
from keras import backend as K
import numpy as np
import sys


# Clustering layer converts input sample (feature) to soft label.
class ClusteringLayer(Layer):
    def __init__(self, n_clusters, weights=None, alpha=1.0, **kwargs):
        if 'input_shape' not in kwargs and 'input_dim' in kwargs:
            kwargs['input_shape'] = (kwargs.pop('input_dim'),)
        super(ClusteringLayer, self).__init__(**kwargs)
        self.n_clusters = n_clusters
        self.alpha = alpha
        self.initial_weights = weights
        self.input_spec = InputSpec(ndim=2)

    def build(self, input_shape):
        assert len(input_shape) == 2
        input_dim = input_shape[1]
        self.input_spec = InputSpec(dtype=K.floatx(), shape=(None, input_dim))
        self.clusters = self.add_weight(shape=(self.n_clusters, input_dim), name='clusters',
                                        initializer='glorot_uniform')
        if self.initial_weights is not None:
            self.set_weights(self.initial_weights)
            del self.initial_weights
        self.built = True

    def call(self, inputs, **kwargs):
        """ student t-distribution, as same as used in t-SNE algorithm.
                 q_ij = 1/(1+dist(x_i, µ_j)^2), then normalize it.
                 q_ij can be interpreted as the probability of assigning sample i to cluster j.
                 (i.e., a soft assignment)
        Arguments:
            inputs: the variable containing data, shape=(n_samples, n_features)
        Return:
            q: student's t-distribution, or soft labels for each sample. shape=(n_samples, n_clusters)
        """
        q = 1.0 / (1.0 + (K.sum(K.square(K.expand_dims(inputs, axis=1) - self.clusters), axis=2) / self.alpha))
        q **= (self.alpha + 1.0) / 2.0
        q = K.transpose(K.transpose(q) / K.sum(q, axis=1))  # Make sure each sample's 10 values add up to 1.
        return q

    def compute_output_shape(self, input_shape):
        assert input_shape and len(input_shape) == 2
        return input_shape[0], self.n_clusters

    def get_config(self):
        config = {'n_clusters': self.n_clusters}
        base_config = super(ClusteringLayer, self).get_config()
        return dict(list(base_config.items()) + list(config.items()))


# computing an auxiliary target distribution
def target_distribution(q_):
    weight = q_ ** 2 / q_.sum(0)
    return (weight.T / weight.sum(1)).T


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


def getLastEncoderLayer(layers):
    for index, layer in enumerate(layers):
        if layer.name == 'repeat_vector_1':
            return index - 1


# help function to redirect print function to file and then back
def print_to_file(filename, message):
    old_std_out = sys.stdout
    sys.stdout = open(filename, 'a+')
    print(message)
    sys.stdout.close()
    sys.stdout = old_std_out


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


def loadFile(path=None):
    if path is not None:
        with open(path, 'r') as file:
            lines = file.readlines()
        file.close()
    else:
        with open('data/dataset.csv', 'r') as file:
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
    correct_DATASET_mean = masked_data.mean()  # 21.11153407758736
    correct_DATASET_std = masked_data.std()    # 1157761522.5453846
    normalised_masked_data = (masked_data - masked_data.mean()) / masked_data.std()  # perform z-normalisation
    final_data = normalised_masked_data.filled(0)  # refill masked values with 0
    final_data_max = final_data.max()    # 1.8548160437801091
    final_data_min = final_data.min()    # -1.854796300701343
    final_data_std = final_data.std()    # 0.582370789833896
    final_data_mean = final_data.mean()  # -0.05886145915563779

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

