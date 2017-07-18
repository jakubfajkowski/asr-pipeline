#!/usr/bin/python3
import os
import sys


root_dir = sys.argv[1]
with open('spk2gender', 'w') as f:
    for dir_location, subdir_list, file_list in sorted(os.walk(root_dir)):
        dir_name = dir_location.split('/')[-1]
        f.write(dir_name + ' ' + dir_name[0].lower() + '\n')

