#!/usr/bin/python3
import sys

from nltk import word_tokenize

text_file_path = sys.argv[1]

words = []
with open(text_file_path, mode='r') as f_in:
    for line in f_in:
        id, utterance = line.split('\t')
        words += word_tokenize(utterance, language='polish')

for word in sorted(set(words)):
    if word != '\'\'':
        print(word)
