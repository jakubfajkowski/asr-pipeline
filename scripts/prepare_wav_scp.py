#!/usr/bin/python3
import os
import sys


root_dir = sys.argv[1]
for dir_location, subdir_list, file_list in sorted(os.walk(root_dir)):
    for file_name in sorted(file_list):
        if file_name.endswith('wav'):
            print(str(file_name.split('.')[0]) + u'\t' + str(os.path.abspath(dir_location)) + u'/' + str(file_name))
