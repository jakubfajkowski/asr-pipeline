#!/usr/bin/python3
import codecs
import glob
import sys


pattern = sys.argv[1]
transcription_tsv_paths = sorted(glob.glob(pattern))

for path in transcription_tsv_paths:
    with codecs.open(path, encoding='UTF-8', mode='r') as f_in:
        for line in f_in:
            print(line.rstrip('\n'))