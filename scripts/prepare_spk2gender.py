#!/usr/bin/python3
import os
import sys
import glob


pattern = sys.argv[1]
corpus_dir_paths = sorted(glob.glob(pattern))

for path in corpus_dir_paths:
    dir_name = os.path.basename(path)
    print(dir_name + u'\t' + dir_name[0].lower())

