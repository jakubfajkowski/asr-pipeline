#!/usr/bin/python3
import os
import sys
import glob


pattern = sys.argv[1]
build_dir = sys.argv[2]
corpus_dir_paths = sorted(glob.glob(pattern))

with open(build_dir + '/spk2gender', encoding='UTF-8', mode='w') as f_out:
    for path in corpus_dir_paths:
        dir_name = os.path.basename(path)
        f_out.write(dir_name + u'\t' + dir_name[0].lower() + '\n')

