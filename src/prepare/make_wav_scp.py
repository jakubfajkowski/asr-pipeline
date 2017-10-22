#!/usr/bin/python3
import glob
import sys
import os

pattern = sys.argv[1]

wav_paths = sorted(glob.glob(pattern))
for path in wav_paths:
    speaker_id = os.path.basename(os.path.dirname(path))
    utterance_id = os.path.basename(path).split('.')[0]
    abs_path = os.path.abspath(path)
    print(utterance_id + '\t' + abs_path)
