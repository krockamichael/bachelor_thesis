"""pairplot test"""
# import matplotlib.pyplot as plt
# import pandas as pd
# import seaborn as sns
# df = pd.read_csv('model_predictions.csv', delimiter=',', header=None)
# sns.set(style='ticks')
# sns.pairplot(df, hue=7)
# plt.show()

"""get encoder output"""
# model.layers[-2].output

"""model name test"""
# from keras import Model
# from keras.engine.saving import load_model
# from keras.optimizers import SGD
# from utils import getLastEncoderLayer, ClusteringLayer, getClusteringModelName
#
# n_clusters = 7
# autoencoder = load_model('models/LSTM_128_mask_epochs_300_BS_128_acc_89.04606699943542.h5')
# output_layer_index = getLastEncoderLayer(autoencoder.layers)
#
# # get only encoder part
# encoder = Model(inputs=autoencoder.layers[0].input, outputs=autoencoder.layers[output_layer_index].output, name='encoder')
# for layer in encoder.layers:
#     layer.trainable = False
# clustering_layer = ClusteringLayer(n_clusters, name='clustering')(encoder.output)
# model = Model(inputs=encoder.input, outputs=clustering_layer, name='clustering_model')
#
# model.load_weights('clustering_weights/LSTM_2_clusters_7_bs_128.h5')
# model.compile(optimizer=SGD(0.01, 0.9), loss='kld')
# print(model.summary())
# print(getClusteringModelName(model, n_clusters, 128))

"""get max probability value for each label, print number of samples with label + create csv for each label with names of files"""
# import pandas as pd
# from utils import loadFile
# import csv
# THE_NUMBER = 7
# df = pd.read_csv('testing/test_2/temp.csv', delimiter=',', header=None)
# print(df.iloc[:, 0:THE_NUMBER].max())
# print(df[THE_NUMBER].value_counts())

# names, data = loadFile()
# name_storage = []
# for i in range(0, THE_NUMBER):
#     name_storage.append([])
#     filename = 'temp_1/' + str(i) + '.csv'
#     with open(filename, 'w', newline='') as file:
#         thewriter = csv.writer(file)
#         for name, label in zip(names, df[THE_NUMBER]):
#             if label == i:
#                 name_storage[i].append(name)
#                 thewriter.writerow([name])
#         file.close()

# print('a')


"""confusion matrix"""
# import seaborn as sns
# import matplotlib.pyplot as plt
# from sklearn.metrics import confusion_matrix
#
# df = pd.read_csv('temp/temp.csv', delimiter=',', header=None)
# df_1 = pd.read_csv('temp_1/temp.csv', delimiter=',', header=None)
#
# sns.set(font_scale=3)
# conf_matrix = confusion_matrix(df[7], df_1[7])
# plt.figure(figsize=(16, 14))
# sns.heatmap(conf_matrix, annot=True, fmt='d', annot_kws={'size': 20})
# plt.title('Confusion matrix', fontsize=30)
# plt.ylabel('Encoder label', fontsize=25)
# plt.xlabel('Clustering label', fontsize=25)
# plt.savefig('temp/conf_temp_temp_1.png')
# plt.savefig('temp_1/conf_temp_temp_1.png')
# plt.show()


"""TSNE"""
# import matplotlib.pyplot as plt
# import pandas as pd
# import numpy as np
# import seaborn as sns
# from utils import loadFile, getClusteringModel_andEncoder
# from sklearn.manifold import TSNE
# import matplotlib.patheffects as PathEffects
# import time
#
#
# def fashion_scatter(x, colors):
#     # choose a color palette with seaborn.
#     num_classes = len(np.unique(colors))
#     palette = np.array(sns.color_palette("hls", num_classes))
#
#     # create a scatter plot.
#     f = plt.figure(figsize=(8, 8))
#     ax = plt.subplot(aspect='equal')
#     sc = ax.scatter(x[:, 0], x[:, 1], lw=0, s=40, c=palette[colors.astype(np.int)])
#     plt.xlim(-25, 25)
#     plt.ylim(-25, 25)
#     ax.axis('off')
#     ax.axis('tight')
#
#     # add the labels for each digit corresponding to the label
#     txts = []
#
#     for i in range(num_classes):
#         # Position of each label at median of data points.
#
#         xtext, ytext = np.median(x[colors == i, :], axis=0)
#         txt = ax.text(xtext, ytext, str(i), fontsize=24)
#         txt.set_path_effects([
#             PathEffects.Stroke(linewidth=5, foreground="w"),
#             PathEffects.Normal()])
#         txts.append(txt)
#
#     plt.show()
#     return f, ax, sc, txts
#
#
# labels = pd.read_csv('clustering_weights/LSTM_2_clusters_7_bs_128_predictions.csv', delimiter=',', header=None)
# labels = labels[7]
# names, data = loadFile()
# model, encoder = getClusteringModel_andEncoder(7, 128, train=False)
# x_model = model.predict(data, verbose=1)
# tsne_out = TSNE().fit_transform(x_model)
# time_start = time.time()
# fashion_scatter(tsne_out, labels)
# print('t-SNE done! Time elapsed: {} seconds'.format(time.time()-time_start))

"""compare csv's"""
# import pandas as pd
# import numpy as np
# THE_NUMBER = 7
# df_128 = pd.read_csv('clustering_weights/LSTM_2_clusters_' + str(THE_NUMBER) + '_bs_128_predictions.csv', delimiter=',', header=None)
# df_256 = pd.read_csv('clustering_weights/LSTM_1_clusters_' + str(THE_NUMBER) + '_bs_256_predictions.csv', delimiter=',', header=None)
# i = 0
# for a, b in zip(df_128.iterrows(), df_256.iterrows()):
#     if a[1][THE_NUMBER] != b[1][THE_NUMBER]:
#         i += 1
# print(str(i))


"""7/128 vs 7/256 --> 47 differences"""
"""10 and 11 - 13k+"""

# import numpy
# names, context_paths = loadFile()
# label_1 = pd.read_csv('full_clust_models/full_LSTM_1_clusters_3_bs_256/1.csv', header=None)
# for j, k in zip(names, context_paths):
#     if j in label_1[0].values:
#         context_paths = numpy.delete(context_paths, k, axis=0)
#
# print('a')

"""get data from layer before last"""
# from keras.models import load_model, Model
# from ClusteringLayer import ClusteringLayer
# from utils import loadFile
# names, data = loadFile()
# model_path = 'full_clust_models/full_LSTM_2_clusters_7_bs_128/full_LSTM_2_clusters_7_bs_128.h5'
# model = load_model(model_path, custom_objects={'ClusteringLayer': ClusteringLayer})
#
# print('Clustering model predicting...')
# x_model = model.predict(data[0].reshape((1, 430, 3)))
# y_model = x_model.argmax(1)
# print('Label: ' + str(y_model[0]))
#
# encoder = Model(inputs=model.layers[0].input, outputs=model.layers[-2].output, name='encoder')
# x_encoder_model = encoder.predict(data[0].reshape((1, 430, 3)))

"""purge the dataset - remove duplicates & files with only 1 context paths"""
# import pandas as pd
# df = pd.read_csv('dataset.csv', delimiter=',', header=None)
# df[['names', 'context_paths']] = df[0].str.split(' ', 1, expand=True)
# df = df.drop(0, axis=1)
# # df.sort_values('context_paths', inplace=True)
# # df.drop_duplicates(subset='context_paths', keep=False, inplace=True)
# # df = df.reset_index(drop=True)
#
# temp = 0
# new_df = pd.DataFrame({"names": [], "context_paths": []})
# for num, i in df.iterrows():
#     if i['context_paths'].count('0,0,0') < 420:
#         # df.drop(i, axis=0)
#         new_df = new_df.append(df.iloc[num])
#         temp += 1
#
# new_df['result'] = new_df['names'].map(str) + ' ' + new_df['context_paths'].map(str)
# new_df = new_df.drop(['names', 'context_paths'], axis=1)
# new_df.to_csv('ONLY_BIG_dataset.csv', index=False, header=False)

"""compare predictions for different masks: 0 vs [0, 0, 0] --> conclusion, 0 should work"""
# from keras.models import Model, load_model
# from utils import loadFile
# import numpy as np
# autoencoder_0_0_0 = load_model('testing/test_9 - X/LSTM_128_mask_epochs_20_BS_128_acc_81.53335452079773.h5')
# autoencoder_0 = load_model('testing/test_8 - X/LSTM_128_mask_epochs_20_BS_128_acc_76.38006210327148.h5')
#
# names, context_paths = loadFile()
# train, validate, test = np.split(context_paths, [int(.7*len(context_paths)), int(.9*len(context_paths))])
#
# # model_1 = Model(inputs=autoencoder.layers[0].input, outputs=autoencoder.layers[0].output)
# # model_1.compile(optimizer='adam', loss='mse')
# # model_2 = Model(inputs=autoencoder.layers[0].input, outputs=autoencoder.layers[1].output)
# # model_2.compile(optimizer='adam', loss='mse')
#
# predict_sample = context_paths[1].reshape((1, 430, 3))
# # same
# # predict_output_1 = model_1.predict(predict_sample, verbose=0)
# # predict_output_2 = model_2.predict(predict_sample, verbose=0)
#
# # not the same
# # predict_output_1 = autoencoder_0_0_0.predict(predict_sample, verbose=0)
# # predict_output_2 = autoencoder_0.predict(predict_sample, verbose=0)
#
# model_2 = Model(inputs=autoencoder_0_0_0.layers[0].input, outputs=autoencoder_0_0_0.layers[1].output)
# model_2.compile(optimizer='adam', loss='mse')
# model_1 = Model(inputs=autoencoder_0.layers[0].input, outputs=autoencoder_0.layers[1].output)
# model_1.compile(optimizer='adam', loss='mse')
# predict_output_1 = model_1.predict(predict_sample, verbose=0)
# predict_output_2 = model_2.predict(predict_sample, verbose=0)
#
# print('a')

# import csv
# from utils import loadFile
from keras.models import load_model
# import pandas as pd
# from ClusteringLayer import ClusteringLayer
#
model = load_model('testing/test_2/LSTM_128_mask_epochs_20_BS_128_acc_81.78999423980713.h5')
print('a')
# destination_folder = ''
# n_clusters = 7
#
# names, context_paths = loadFile()
# x_model = model.predict(context_paths, verbose=0)
# y_model = x_model.argmax(1)
#
# filename = destination_folder + 'temp.csv'
# with open(filename, 'w', newline='') as file:
#     thewriter = csv.writer(file)
#     for x, y, name in zip(x_model, y_model, names):
#         thewriter.writerow([i for i in x] + [str(y), name])
# file.close()
#
# # Load data to a dataframe
# # percentages and labels
# df = pd.read_csv(destination_folder + 'temp.csv', delimiter=',', header=None)
#
# # print the maximum percentage of confidence for each label
# # print the number of samples per label
# print(df.iloc[:, 0:n_clusters].max())
# print(df[n_clusters].value_counts())
#
#
# # Create csv files with labels as titles
# # content is name of data sample (source code file)
# name_storage = []
# for i in range(0, n_clusters):
#     name_storage.append([])
#     filename = destination_folder + str(i) + '.csv'
#     with open(filename, 'w', newline='') as file:
#         thewriter = csv.writer(file)
#         for name, label in zip(names, df[n_clusters]):
#             if label == i:
#                 name_storage[i].append(name)
#                 thewriter.writerow([name])
#         file.close()
