#!/usr/bin/python3
import glob
import os
import shutil
import sys
import random
import math

pattern = sys.argv[1]
destination_dir = sys.argv[2]
ratio = float(sys.argv[3])

source_paths = glob.glob(pattern)
random.shuffle(source_paths)

data_set_size = len(source_paths)
test_set_size = math.ceil(data_set_size * ratio)

test_dir = destination_dir + "/test"
os.makedirs(test_dir)
for source_path in source_paths[:test_set_size]:
    shutil.copy(source_path, test_dir)

train_dir = destination_dir + "/train"
os.makedirs(train_dir)
for source_path in source_paths[test_set_size:]:
    shutil.copy(source_path, train_dir)
