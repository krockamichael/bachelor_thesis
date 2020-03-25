import os
import json
import chardet
import ast
import numpy as np
from context_paths.module_handler import ModuleHandler
from console_progressbar import ProgressBar

data_path = 'C:\\Users\\krock\\Desktop\\FIIT\\Bakalárska práca\\Ubuntu\\luadb\\etc\\luarocks_test\\data'
modules_path = 'C:\\Users\\krock\\Desktop\\FIIT\\Bakalárska práca\\Ubuntu\\luadb\\etc\\luarocks_test\\modules'
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
# print(np.sort(np_nodes))
np_path_lengths = np.asanyarray(path_lengths)
np_context_paths = np.asarray(context_paths)

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
