#!/usr/bin/python3
import codecs
import os
import sys
import re
import glob


file_pattern = sys.argv[1]
regex_pattern = sys.argv[2]


def add_suffix_to_filename(path, suffix):
    return path + suffix


for path in glob.glob(file_pattern):
    tsv_file = add_suffix_to_filename(path, '.tsv')
    old_file = path

    with codecs.open(old_file, encoding='UTF-8', mode='r') as f_in, \
         codecs.open(tsv_file, encoding='UTF-8', mode='w') as f_out:
        raw_text = f_in.read()
        rows = re.findall(regex_pattern, raw_text)

        for row in rows:
            f_out.write('\t'.join(reversed(row)) + '\n')
