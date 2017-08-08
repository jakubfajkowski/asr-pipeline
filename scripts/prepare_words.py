#!/usr/bin/python3
import codecs
import sys
import re
from nltk import word_tokenize


text_file_path = sys.argv[1]
build_dir = sys.argv[2]
words = []

with codecs.open(text_file_path, encoding='UTF-8', mode='r') as f_in:
    raw = f_in.read()
    utterances = str.join(' ', re.findall(r'<s>(.+)</s>', raw))

    words += word_tokenize(utterances, language='polish')

with open(build_dir + '/words', encoding='UTF-8', mode='w') as f_out:
    for word in sorted(set(words)):
        f_out.write(word + '\n')
