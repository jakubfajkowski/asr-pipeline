#!/usr/bin/python3
import sys
import glob
import os

pattern = sys.argv[1]

corpus_audio_dir_paths = sorted(glob.glob(pattern))
for path in corpus_audio_dir_paths:
    dir_name = os.path.basename(path)
    print(dir_name + '\t' + dir_name[0].lower())

