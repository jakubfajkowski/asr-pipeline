#!/usr/bin/python3
import glob
import sys
import os

pattern = sys.argv[1]

wav_paths = sorted(glob.glob(pattern))
for path in wav_paths:
    speaker_id = os.path.basename(os.path.dirname(path))
    wav_name = os.path.basename(path)
    abs_path = os.path.abspath(path)
    print(wav_name + '\t' + abs_path)
