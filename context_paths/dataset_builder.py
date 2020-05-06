import codecs
import csv
import os
from console_progressbar import ProgressBar
from context_paths.module_handler import ModuleHandler


def java_string_hashcode(s):
    # Imitating Java's String#hashCode, because the model is trained on hashed paths
    h = 0
    for c in s:
        h = (31 * h + ord(c)) & 0xFFFFFFFF
    return ((h + 0x80000000) & 0xFFFFFFFF) - 0x80000000


def main():
    file_path = 'C:\\Users\\krock\\Desktop\\FIIT\\Bakalárska práca\\Ubuntu\\luadb\\etc\\luarocks_test\\data_all'
    files = list()

    # r=root, d=directories, f = files
    # list all json files
    for r, d, f in os.walk(file_path):
        for file in f:
            if '.json' in file:
                files.append(os.path.join(r, file))

    pb = ProgressBar(total=len(files), prefix='0 files', suffix='{} files'.format(len(files)),
                     decimals=2, length=50, fill='X', zfill='-')
    progress = 0

    master_file_path = 'C:\\Users\\krock\\Desktop\\FIIT\\Bakalárska práca\\Ubuntu\\luadb\\etc\\luarocks_test\\dataset.csv'
    with codecs.open(master_file_path, 'w+', 'utf-8') as csvfile:
        filewriter = csv.writer(csvfile)
        MAX_CONTEXTS = 430
        unique_nodes = list()
        unique_paths = list()
        MAX_NODE = 2138153206
        MAX_PATH = 2147397843

        # make input for all .json files
        for file in files:
            module_handler = ModuleHandler(file)
            context_paths = module_handler.get_context_paths()
            file_context_paths = module_handler.data['url'].replace('.lua', '')\
                .replace('https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part1/', '')\
                .replace('https://raw.githubusercontent.com/katka-juhasova/BP-data/master/modules-part2/', '') + ' '

            # if needed reduce number of context paths to match MAX_CONTEXTS = 430
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

            # start writing to file
            for i in context_paths:
                source_node = i[0][0] + '|' + i[0][1]
                hashed_source_node = java_string_hashcode(source_node)
                if hashed_source_node not in unique_nodes:
                    unique_nodes.append(hashed_source_node)
                if hashed_source_node > MAX_NODE:
                    MAX_NODE = hashed_source_node

                path = ''.join(i[1])
                hashed_path = java_string_hashcode(path)
                if hashed_path not in unique_paths:
                    unique_paths.append(hashed_path)
                if hashed_path > MAX_PATH:
                    MAX_PATH = hashed_path

                target_node = i[2][0] + '|' + i[2][1]
                hashed_target_node = java_string_hashcode(target_node)
                if hashed_target_node not in unique_nodes:
                    unique_nodes.append(hashed_target_node)
                if hashed_target_node > MAX_NODE:
                    MAX_NODE = hashed_target_node

                file_context_paths += str(hashed_source_node) + ',' + str(hashed_path) + ',' + str(hashed_target_node) + ' '

            # this is on the level of NUMBER OF INPUTS, if number of context_paths < MAX_CONTEXTS, do zero-padding
            if len(context_paths) < MAX_CONTEXTS:
                for i in range(MAX_CONTEXTS - len(context_paths)):
                    file_context_paths += '0,0,0 '
            if file_context_paths[-1] == ' ':
                file_context_paths = file_context_paths[:-1]

            delimited = file_context_paths.split(sep=' ')
            if len(delimited) != MAX_CONTEXTS + 1:
                exit('Too many contexts, trimming failed.')

            filewriter.writerow([file_context_paths])

            # update progress bar
            progress += 1
            pb.print_progress_bar(progress)

    print('MAX_NODE: {}'.format(MAX_NODE))
    print('Number of unique nodes: {}'.format(len(unique_nodes)))
    print('MAX_PATH: {}'.format(MAX_PATH))
    print('Number of unique paths: {}'.format(len(unique_paths)))


if __name__ == '__main__':
    main()
