import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
from context_paths.module_handler import ModuleHandler
from ClusteringLayer import ClusteringLayer
from keras.models import load_model
import numpy as np


def java_string_hashcode(s):
    # Imitating Java's String#hashCode, because the model is trained on hashed paths
    h = 0
    for c in s:
        h = (31 * h + ord(c)) & 0xFFFFFFFF
    return ((h + 0x80000000) & 0xFFFFFFFF) - 0x80000000


MAX_CONTEXTS = 430
# filepath = 'C:\\Users\\krock\\Desktop\\FIIT\\BP\\Ubuntu\\luadb\\etc\\luarocks_test\\modules\\30log\\share\\lua\\5.1\\30log.lua'
# TODO change path to json file
jsonpath = 'C:\\Users\\krock\\Desktop\\FIIT\\BP\\Ubuntu\\luadb\\etc\\luarocks_test\\data_all\\30log\\AST1.json'

# get context paths
module_handler = ModuleHandler(jsonpath)
context_paths = module_handler.get_context_paths()

# get module name
module_name = module_handler.data['url'].replace('.lua', '') \
                         .replace('https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part1/', '') \
                         .replace('https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part2/', '') + ' '

# trim number of context paths if they exceed MAX_CONTEXTS
while len(context_paths) > MAX_CONTEXTS * 2:
    context_paths = context_paths[0::2]  # get every second element --> halve list length, this is FAST

excess_contexts = len(context_paths) - MAX_CONTEXTS
if excess_contexts > 0:
    new_contexts = list()
    for _, i in enumerate(context_paths):
        if _ < 2 * excess_contexts:
            if _ % 2 == 1:
                new_contexts.append(i)
        else:
            context_paths = [x for x in context_paths if x not in new_contexts]
            break

# code context paths using java hashstring
file_context_paths = ''
for i in context_paths:
    source_node = i[0][0] + '|' + i[0][1]
    hashed_source_node = java_string_hashcode(source_node)

    path = ''.join(i[1])
    hashed_path = java_string_hashcode(path)

    target_node = i[2][0] + '|' + i[2][1]
    hashed_target_node = java_string_hashcode(target_node)

    file_context_paths += str(hashed_source_node) + ',' + str(hashed_path) + ',' + str(hashed_target_node) + ' '

# do zero-padding
if len(context_paths) < 430:
    for i in range(MAX_CONTEXTS - len(context_paths)):
        file_context_paths += '0,0,0 '

# remove excess white-space at the end
if file_context_paths[-1] == ' ':
    file_context_paths = file_context_paths[:-1]

# double check if the number of context paths is correct
# TODO can be removed
delimited = file_context_paths.split(sep=' ')
if len(delimited) != MAX_CONTEXTS:
    exit('Too many contexts, trimming failed.')

# generate dataset in the form of (n_samples, n_context_paths, source_path_target)
triplets = [file_context_paths.replace('"', '').replace('\n', '').split(" ")]  # (18000, 430)
singles = []  # (18000, 430, 3)
for t in triplets:
    singles += [[trp.split(',') for trp in t]]

data = np.ma.array(singles).astype(np.int32)
masked_data = np.ma.masked_equal(data, 0)  # values without zero-padding, to perform normalisation

# normalise data, get mean and std from training, here its hardcoded
print('Normalising data...')
masked_data_mean = -120.57979590730959
masked_data_std = 1115300671.9887397
normalised_masked_data = (masked_data - masked_data_mean) / masked_data_std  # perform z-normalisation
final_data = normalised_masked_data.filled(0)  # refill masked values with 0

# load model and generate label
# TODO change path to model
model_path = 'full_clust_models/full_LSTM_2_clusters_7_bs_128/full_LSTM_2_clusters_7_bs_128.h5'
model = load_model(model_path, custom_objects={'ClusteringLayer': ClusteringLayer})
print('Clustering model predicting...')
x_model = model.predict(final_data)
y_model = x_model.argmax(1)
print('Label: ' + str(y_model[0]))
