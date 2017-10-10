#!/usr/bin/python3
import glob
import sys
import random
import math
import os
import shutil

pattern = sys.argv[1]
build_dir = sys.argv[2]
ratio = float(sys.argv[3])

speaker_dirs = glob.glob(pattern)
random.shuffle(speaker_dirs)

data_set_size = len(speaker_dirs)
pivot = math.ceil(data_set_size * ratio)

test_dir = build_dir + "/test"
for speaker_dir in speaker_dirs[:pivot]:
    speaker_id = os.path.basename(speaker_dir)
    destination_dir = test_dir + '/' + speaker_id
    shutil.copytree(speaker_dir, destination_dir)

train_dir = build_dir + "/train"
for speaker_dir in speaker_dirs[pivot:]:
    speaker_id = os.path.basename(speaker_dir)
    destination_dir = train_dir + '/' + speaker_id
    shutil.copytree(speaker_dir, destination_dir)
