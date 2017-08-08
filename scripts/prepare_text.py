#!/usr/bin/python3
import codecs
import glob
import sys


pattern = sys.argv[1]
build_dir = sys.argv[2]
transcription_tsv_paths = sorted(glob.glob(pattern))

with open(build_dir + '/text', encoding='UTF-8', mode='w') as f_out:
    for path in transcription_tsv_paths:
        with codecs.open(path, encoding='UTF-8', mode='r') as f_in:
            for line in sorted(f_in):
                f_out.write(line.rstrip('\n') + '\n')