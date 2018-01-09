#!/usr/bin/python3
import codecs
import glob
import os
import sys


pattern = sys.argv[1]
encoding = sys.argv[2]

def add_prefix_to_filename(path, prefix):
    filename = os.path.basename(path)
    dirname = os.path.dirname(path)

    return dirname + '/' + prefix + filename

for path in glob.glob(pattern):
    unicode_file = path
    old_file = add_prefix_to_filename(path, '_')

    os.rename(path, old_file)

    with codecs.open(old_file, encoding=encoding, mode='r') as f_in, \
         codecs.open(unicode_file, encoding='UTF-8', mode='w') as f_out:
        for line in f_in:
            f_out.write(line)
