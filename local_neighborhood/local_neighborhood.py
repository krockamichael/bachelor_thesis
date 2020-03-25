import json
import os
import chardet
import ast

path = 'C:\\Users\\krock\\Desktop\\FIIT\\Bakalárska práca\\Ubuntu\\luadb\\etc\\luarocks_test\\data'
AST_list = list()
files = list()
size = 32
zero_node = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]
# index, type, count, depth
ROOT_node = [[0, 0, 1, 1, {'index': 0, 'master_index': 0, 'position': 0, 'container': 0, 'children_count': 0}]]
AST = [ROOT_node]


class JSON(object):
    def __init__(self, data):
        self.module = None
        self.nodes = None
        self.nodes_count = None
        self.__dict__ = json.loads(data)


def code_node_type(text):
    if text == 'other':
        return 0.2
    elif text == 'require':
        return 0.4
    elif text == 'variable':
        return 0.6
    elif text == 'function':
        return 0.8
    elif text == 'interface':
        return 1.0
    else:  # root maybe?
        return 0.0


def add_node(node, depth, parent):
    if parent == ROOT_node:
        node['parent'] = 0
    elif node == ROOT_node[0]:
        return ROOT_node[0]
    elif parent != 0:
        node['parent'] = parent['master_index']

    node_type = code_node_type(node['container'])
    return [node['master_index'], node_type, 1, depth, node]


def handle_children(Ast, node, depth):
    if node['children_count'] > 0:
        for child in node['children']:
            Ast.append([add_node(child, depth, node)])
            handle_children(Ast, child, depth + 1)


def compute_main_nodes(Ast, json_object):
    depth = 0
    for node in json_object.nodes:
        Ast.append([add_node(node, depth, ROOT_node)])
        handle_children(Ast, node, depth + 1)
    ROOT_node[0][4]['children'] = json_object.nodes
    ROOT_node[0][4]['children_count'] = len(json_object.nodes)


def sort_sixth(val):
    return val[5]


def sort_third(val):
    return val[0][4]['characters_count']


def calc_position(pos1, pos2):
    if pos1 - pos2 < 0:
        return (pos1 - pos2) * (-1)
    else:
        return pos1 - pos2


def order_neighborhood(array):
    depth_1, depth_2, depth_3, depth_4, length = [], [], [], [], []

    for i in array:
        if i[3] not in length:
            length.append(i[3])

    if len(length) == 1:  # one level
        array.sort(key=sort_sixth)
        return array

    elif len(length) == 2:  # two levels
        for i in array:
            if i[3] == 1:
                depth_1.append(i)
            elif i[3] == 2:
                depth_2.append(i)

        depth_1.sort(key=sort_sixth)
        depth_2.sort(key=sort_sixth)
        return depth_1 + depth_2

    elif len(length) == 3:
        for i in array:
            if i[3] == 1:
                depth_1.append(i)
            elif i[3] == 2:
                depth_2.append(i)
            elif i[3] == 3:
                depth_3.append(i)

        depth_1.sort(key=sort_sixth)
        depth_2.sort(key=sort_sixth)
        depth_3.sort(key=sort_sixth)
        return depth_1 + depth_2 + depth_3

    elif len(length) == 4:
        for i in array:
            if i[3] == 1:
                depth_1.append(i)
            elif i[3] == 2:
                depth_2.append(i)
            elif i[3] == 3:
                depth_3.append(i)
            elif i[3] == 4:
                depth_4.append(i)

        depth_1.sort(key=sort_sixth)
        depth_2.sort(key=sort_sixth)
        depth_3.sort(key=sort_sixth)
        depth_4.sort(key=sort_sixth)
        return depth_1 + depth_2 + depth_3 + depth_4


def append_node(master_node, node, depth, array):
    temp = add_node(node, depth, 0)
    # some problems with root node, so manualy set depth
    temp[3] = depth
    if node == ROOT_node[0][4]:
        position_difference = 0
    else:
        position_difference = calc_position(master_node[0][4]['position'], node['position'])
    temp.append(position_difference)

    # check if it isn't already in array in different depth
    for i in array:
        if temp[0] == i[0]:
            return

    # check if node isn't master node in different depth
    if temp[0] == master_node[0][0]:
        return

    array.append(temp)


def get_parent(Ast, node):
    parent_index = node[4]['parent']
    return Ast[parent_index][0]


def append_depth1(Ast, node, local_neighborhood):
    # append direct children
    if node[0][4]['children_count'] > 0:
        for child in node[0][4]['children']:
            append_node(node, child, 1, local_neighborhood)

    # append parent if node is not ROOT
    if node[0][0] != 0:
        parent_node = get_parent(Ast, node[0])
        append_node(node, parent_node[4], 1, local_neighborhood)


def append_depth2(Ast, node, local_neighborhood):
    # append grandchildren
    if node[0][4]['children_count'] > 0:
        for child in node[0][4]['children']:
            if child['children_count'] > 0:
                for grandchild in child['children']:
                    append_node(node, grandchild, 2, local_neighborhood)

    # if node is not ROOT
    if node[0][0] != 0:
        parent_node = get_parent(Ast, node[0])
        # if parent is ROOT, append only some siblings
        if parent_node[0] == 0:
            do_root(Ast, node, local_neighborhood, 2)
        else:
            # append siblings
            if parent_node[4]['children_count'] > 0:
                for i in parent_node[4]['children']:
                    append_node(node, i, 2, local_neighborhood)

            # append grandparent
            grandparent_node = get_parent(Ast, parent_node)
            append_node(node, grandparent_node[4], 2, local_neighborhood)


def append_depth3(Ast, node, local_neighborhood):
    # append grand_grandchildren
    if node[0][4]['children_count'] > 0:
        for child in node[0][4]['children']:
            if child['children_count'] > 0:
                for grandchild in child['children']:
                    if grandchild['children_count'] > 0:
                        for grand_grandchild in grandchild['children']:
                            append_node(node, grand_grandchild, 3, local_neighborhood)

    # if node is not ROOT
    if node[0][0] != 0:
        parent_node = get_parent(Ast, node[0])

        # if parent node is not ROOT
        if parent_node[0] == 0:
            do_root(Ast, node, local_neighborhood, 3)
        else:
            grandparent_node = get_parent(Ast, parent_node)

            # check if grandparent node is ROOT
            if grandparent_node[0] == 0:
                do_root(Ast, node, local_neighborhood, 3)
            else:
                # append siblings of parent
                if grandparent_node[4]['children_count'] > 0:
                    for i in grandparent_node[4]['children']:
                        append_node(node, i, 3, local_neighborhood)

                grand_grandparent_node = get_parent(Ast, grandparent_node)
                append_node(node, grand_grandparent_node[4], 3, local_neighborhood)


def append_depth4(Ast, node, local_neighborhood):
    # append grand_grand_grandchildren
    if node[0][4]['children_count'] > 0:
        for child in node[0][4]['children']:
            if child['children_count'] > 0:
                for grandchild in child['children']:
                    if grandchild['children_count'] > 0:
                        for grand_grandchild in grandchild['children']:
                            if grand_grandchild['children_count'] > 0:
                                for grand_grand_grandchild in grand_grandchild['children']:
                                    append_node(node, grand_grand_grandchild, 4, local_neighborhood)

    # if node is not ROOT
    if node[0][0] != 0:
        parent_node = get_parent(Ast, node[0])

        # check if parent node is not ROOT
        if parent_node[0] != 0:
            grandparent_node = get_parent(Ast, parent_node)

            # check if grandparent node is not ROOT
            if grandparent_node[0] != 0:
                grand_grandparent_node = get_parent(Ast, grandparent_node)

                # check if grand_grandparent is ROOT
                if grand_grandparent_node[0] == 0:
                    do_root(Ast, node, local_neighborhood, 4)
                else:
                    # append siblings of grandparent
                    if grand_grandparent_node[4]['children_count'] > 0:
                        for i in grand_grandparent_node[4]['children']:
                            append_node(node, i, 4, local_neighborhood)

                    grand_grand_grandparent_node = get_parent(Ast, grand_grandparent_node)
                    append_node(node, grand_grand_grandparent_node[4], 4, local_neighborhood)


def root_children(tmp_index, node, depth, depth_counter, local_neighborhood):
    tmp_node = ROOT_node[0][4]['children'][tmp_index]
    append_node(node, tmp_node, depth, local_neighborhood)
    depth_counter += 1

    if depth_counter < depth and tmp_node['children_count'] > 0:
        depth_counter += 1
        for child in tmp_node['children']:
            append_node(node, child, 3, local_neighborhood)

            if depth_counter < depth and child['children_count'] > 0:
                depth_counter += 1
                for grandchild in child['children']:
                    append_node(node, grandchild, 4, local_neighborhood)


def do_root(Ast, node, local_neighborhood, depth):
    # get index of parent which is a child of ROOT node
    if node[0][3] == 0:
        curr_index = node[0][4]['index']
    elif node[0][3] == 1:
        parent_index = node[0][4]['parent']
        curr_index = Ast[parent_index][0][4]['index']
    elif node[0][3] == 2:
        grand_parent_index = node[0][4]['parent']
        parent_index = Ast[grand_parent_index][0][4]['parent']
        curr_index = Ast[parent_index][0][4]['index']

    # iterate 4 times up and 4 times down around index number (in ROOT children)
    for i in range(4):
        depth_counter = 1  # input depth is always at least 1 or greater
        tmp_index = curr_index + i

        if tmp_index < ROOT_node[0][4]['children_count']:
            root_children(tmp_index, node, depth, depth_counter, local_neighborhood)
        else:
            break

    for i in range(4):
        depth_counter = 1  # input depth is always at least 1 or greater
        tmp_index = curr_index - (i + 2)

        if tmp_index > 0:
            root_children(tmp_index, node, depth, depth_counter, local_neighborhood)
        else:
            break


def handle_neighborhood_size_5(Ast, node):
    local_neighborhood = []

    # POSTUP:
    # depth_1: children, parent
    # depth_2: grandchildren, grandparent, siblings
    # depth_3: grand_grandchildren, siblings of parent, grand_grandparent
    # depth_4: grand_grand_grandchildren, siblings of grandparent, grand_grand_grandparent

    # append children and parent
    append_depth1(Ast, node, local_neighborhood)

    # append grandchildren and grandparent or siblings if grandparent is root
    if len(local_neighborhood) < 4:
        append_depth2(Ast, node, local_neighborhood)
    if len(local_neighborhood) < 4:
        append_depth3(Ast, node, local_neighborhood)
    if len(local_neighborhood) < 4:
        append_depth4(Ast, node, local_neighborhood)

    local_neighborhood = order_neighborhood(local_neighborhood)
    return local_neighborhood[0:4]


def compute_local_neighborhood(Ast):
    for node in Ast:
        if node == zero_node:
            return
        local_neighborhood = handle_neighborhood_size_5(Ast, node)
        node += local_neighborhood


def clean_up_ast(Ast):
    for node in Ast:
        if node == [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]:
            break
        for i in range(5):
            while len(node[i]) != 3:
                del node[i][-1]


def update_neighborhood(Ast, node):
    node_index = Ast.index(node)
    node_master_index = node[0][0]

    for i in range(4):
        temp_index = node_index + (i + 1)
        if temp_index < len(Ast) and not Ast[temp_index] == zero_node:
            for j in range(4):
                if node_master_index == Ast[temp_index][j + 1][0]:
                    Ast[temp_index][j + 1][2] = node[0][2]

    for i in range(4):
        temp_index = node_index - (i + 1)
        if temp_index > -1 and not Ast[temp_index] == zero_node:
            for j in range(4):
                if node_master_index == Ast[temp_index][j + 1][0]:
                    Ast[temp_index][j + 1][2] = node[0][2]


def add_to_group(Ast, index, node_type, group):
    if Ast[index][0][1] == node_type:
        group.append(Ast[index])
        add_to_group(Ast, index + 1, node_type, group)


def get_groups(Ast, reduce_by):
    reduced_length, i = 0, 1

    while i < len(Ast) and reduced_length < reduce_by:  # iterate Ast nodes which are present after removal of excess
        current = Ast[i]
        current_type = current[0][1]
        previous = Ast[i - 1]
        i = i + 1
        if previous == ROOT_node:
            continue
        else:
            previous_type = previous[0][1]

        if previous_type == current_type:     # check if node type is the same
            group = [previous, current]
            add_to_group(Ast, i, current_type, group)   # create a group of nodes with the same type

            group.sort(key=sort_third, reverse=True)    # sort in a descending order based on character_count
            winner = group[0]
            del group[0]

            if size > len(Ast) - len(group):    # check if we don't remove more nodes than necessary
                excess_trim = size - (len(Ast) - len(group))
                while excess_trim:
                    del group[0]
                    excess_trim -= 1

            Ast = [x for x in Ast if x not in group]    # remove excess nodes
            winner[0][2] = len(group) + 1   # increase indicator of grouped nodes in one node
            update_neighborhood(Ast, winner)
            reduced_length = reduced_length + len(group)

    return Ast, reduced_length


def select_nodes_if_size_exceeded(Ast):
    if len(Ast) > size:
        reduce_by = len(Ast) - size
        Ast, number = get_groups(Ast, reduce_by)
        reduce_by -= number
        print('Reduced by ' + str(number) + ' nodes.')
        print('Size of AST: ' + str(len(Ast)) + '.')
        return Ast
    else:
        print("Can't use grouping heuristic.")
        return Ast


def do_zero_padding(Ast):
    while len(Ast) < size:
        Ast.append(zero_node)


def main(Ast, json_object):
    compute_main_nodes(Ast, json_object)

    if len(Ast) < 5:
        print("Module has too little nodes.")
        return

    compute_local_neighborhood(Ast)
    Ast = select_nodes_if_size_exceeded(Ast)

    if len(Ast) > size:
        Ast = Ast[0:size]
    else:
        do_zero_padding(Ast)

    clean_up_ast(Ast)

    if len(Ast) != 1:
        AST_list.append(Ast)

    for i in Ast:   # TODO save to file?
        print(i)


# r=root, d=directories, f=files
for r, d, f in os.walk(path):
    for file in f:
        if '.json' in file:
            files.append(os.path.join(r, file))

for file in files:
    rawdata = open(file, 'rb').read()
    result = chardet.detect(rawdata)

    if result['encoding'] not in ['ascii', 'utf-8']:
        rawdata = rawdata.decode('iso-8859-1').encode('utf8')
        result = chardet.detect(rawdata)

    try:
        json_obj = JSON(rawdata)

        print('\nIN TRY: ', json_obj.module)
        main(AST, json_obj)
        ROOT_node = [[0, 0, 1, 1, {'index': 0, 'master_index': 0, 'position': 0, 'container': 0, 'children_count': 0}]]
        AST = [ROOT_node]

    except UnicodeError:
        data_str = rawdata.decode('utf8')
        data_dict = ast.literal_eval(data_str)
        json_dump = json.dumps(data_dict)
        json_obj = JSON(json_dump)

        print('\nIN EXCEPT: ', json_obj.module)
        main(AST, json_obj)
        ROOT_node = [[0, 0, 1, 1, {'index': 0, 'master_index': 0, 'position': 0, 'container': 0, 'children_count': 0}]]
        AST = [ROOT_node]
