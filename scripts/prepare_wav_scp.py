#!/usr/bin/python3
import os
import sys


root_dir = sys.argv[1]
with open('wav.scp', 'w') as f:
    for dir_location, subdir_list, file_list in sorted(os.walk(root_dir)):
        for file_name in sorted(file_list):
            if file_name.split('.')[1] == 'wav':
                f.write(file_name.split('.')[0] + ' ' +
                        os.path.abspath(dir_location) + '/' + file_name + '\n')
