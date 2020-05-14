import os
import json
import chardet
import ast
import numpy as np
from context_paths.module_handler import ModuleHandler
import matplotlib.pyplot as plt
from console_progressbar import ProgressBar

# update data_path to point to folder where all json files are stored IF a different dataset is selected
data_path = '../data/data_json'
# update modules_path to point to folder where all downloaded modules are stored IF a different dataset is selected
modules_path = '../data/modules'

"""
this script calcaulates interesting statistics from the dataset such as the number of:
    - downloaded repositories
    - successfully processed repositories
    - processed modules == json files in data_path
    - processed modules with nodes_count > 0 (some have 0 nodes (e.g. init.lua))
    - minimum, maximum, mean and median of nodes across all modules
    - minimum, maximum, mean and median LENGTH of paths across all modules
    - minimum, maximum, mean and median COUNT of context_paths across all modules
        - context_path is a triplet of (source_leaf, path, target_leaf)
        - for more info check bachelor thesis documentation chapter 6.2.1 or chapter 4.1
"""

files = list()
nodes = list()
path_lengths = list()
context_paths = list()

# r=root, d=directories, f = files
# list all json files
for r, d, f in os.walk(data_path):
    for file in f:
        if '.json' in file:
            files.append(os.path.join(r, file))

pb = ProgressBar(total=len(files), prefix='0 files', suffix='{} files'.format(len(files)),
                 decimals=2, length=50, fill='X', zfill='-')
progress = 0

for file in files:
    # there was some problem with files encoding,
    # e.g. /home/katka/Desktop/skola/BP/luadb/etc/luarocks_test/data/ads1015/AST39.json
    # so we just want to have it encoded as utf-8 or ascii
    raw_data = open(file, 'rb').read()
    result = chardet.detect(raw_data)
    data = dict()

    if result['encoding'] not in ['ascii', 'utf-8']:
        raw_data = raw_data.decode('iso-8859-1').encode('utf8')
        result = chardet.detect(raw_data)

    try:
        data = json.loads(raw_data)

    except UnicodeError:
        data_str = raw_data.decode('utf8')
        data = ast.literal_eval(data_str)

    # print(data['nodes_count'])
    if data['nodes_count'] > 0:
        nodes.append(data['nodes_count'])

    module_handler = ModuleHandler(file, json_dict=data)
    paths = module_handler.get_paths()
    for path in paths:
        number_1 = len(path)
        path_lengths.append(number_1)

    number = len(module_handler.get_context_paths())
    context_paths.append(number)

    # update progress bar
    progress += 1
    pb.print_progress_bar(progress)

np_nodes = np.asarray(nodes)
np_path_lengths = np.asanyarray(path_lengths)
np_context_paths = np.asarray(context_paths)

fig = plt.figure(figsize=(9, 3))

ax = plt.subplot(1, 3, 1)
ax.boxplot(np_nodes)
ax.set_title('Number of nodes')

ax = plt.subplot(1, 3, 2)
ax.boxplot(np_path_lengths)
ax.set_title('Path lengths')

ax = plt.subplot(1, 3, 3)
ax.boxplot(np_context_paths)
ax.set_yscale('log')
ax.set_title('Number of context paths')

plt.show()

print('\nDownloaded repositories: {}'.format(len(os.listdir(modules_path))))
print('Successfully processed repositories: {}'.format(len(os.listdir(data_path))))
# processed modules are basically all found .json files
print('Processed modules: {}'.format(len(files)))
# some of the .json files have 0 nodes, for example init.lua files 
print('Processed modules with nodes_count > 0: {}'.format(len(nodes)))
print('--------------------------------------------------')
print('Minimum nodes count: {}'.format(min(nodes)))
print('Maximum nodes count: {}'.format(max(nodes)))
print('Mean nodes count: {}'.format(np.mean(np_nodes)))
print('Median for nodes count: {}'.format(np.median(np_nodes)))
print('--------------------------------------------------')
print('Minimum length of path: {}'.format(min(path_lengths)))
print('Maximum length of path: {}'.format(max(path_lengths)))
print('Mean length of path: {}'.format(np.mean(np_path_lengths)))
print('Median for length of path: {}'.format(np.median(np_path_lengths)))
print('--------------------------------------------------')
print('Minimum count of context paths for 1 module: {}'.format(min(context_paths)))
print('Maximum count of context paths for 1 module: {}'.format(max(context_paths)))
print('Mean length of context paths: {}'.format(np.mean(np_context_paths)))
print('Median for length of context paths: {}'.format(np.median(np_context_paths)))
