#!/usr/bin/python3
import os
import glob
import sys


pattern = sys.argv[1]
build_dir = sys.argv[2]
wav_paths = sorted(glob.glob(pattern))

with open(build_dir + '/wav.scp', encoding='UTF-8', mode='w') as f_out:
    for path in wav_paths:
        speaker_id = os.path.basename(os.path.dirname(path))
        wav_name = os.path.basename(path)
        abs_path = os.path.abspath(path)
        f_out.write(speaker_id + '-' + wav_name + '\t' + abs_path + '\n')