import codecs
import os
import sys
import re
from nltk import word_tokenize


root_dir = sys.argv[1]
words = []

for dir_location, subdir_list, file_list in sorted(os.walk(root_dir)):
    for filename in file_list:
        if filename.split('.')[-1] == "transcription":
            with codecs.open(dir_location + '/' + filename, encoding='windows-1250', mode='r') as f_in:
                raw = f_in.read()
                utterances = str.join(' ', re.findall(r'<s>(.+)</s>', raw))

                words += word_tokenize(utterances, language='polish')

with open('words', 'w') as f_out:
    for word in set(words):
        f_out.write(word + '\n')
