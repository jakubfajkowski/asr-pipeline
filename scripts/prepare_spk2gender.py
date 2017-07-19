#!/usr/bin/python3
import os
import sys


root_dir = sys.argv[1]
for dir_location, subdir_list, file_list in sorted(os.walk(root_dir)):
    dir_name = str(dir_location.split('/')[-1])
    print(dir_name + u'\t' + dir_name[0].lower())

