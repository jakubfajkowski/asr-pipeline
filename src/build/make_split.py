#!/usr/bin/python3

import argparse
import random
import math
import os
import shutil
import logging

logging.basicConfig(format='[%(asctime)s][%(levelname)s]    %(message)s')

def parse_args():
    parser = argparse.ArgumentParser(description='Splits provided dirs into train and test sets.')
    parser.add_argument('dirs', metavar='DIRS', type=str, nargs='+',
                        help='Dirs to split.')
    parser.add_argument('-d', '--data-dir', dest='data_dir', default='.', type=str,
                        help='Output dir containing train and test folder.')
    parser.add_argument('-s', '--split-ratio', dest='split_ratio', default=0.1, type=float,
                        help='Test set to all dirs number ratio.')
    return parser.parse_args()

def copy(dirs, data_dir):
    for dir in dirs:
        dirname = os.path.basename(dir)
        destination_dir = data_dir + '/' + dirname
        shutil.copytree(dir, destination_dir)

if __name__ == '__main__':
    arguments = parse_args()

    dirs = arguments.dirs
    data_dir = arguments.data_dir
    split_ratio = arguments.split_ratio

    random.shuffle(dirs)
    pivot = math.ceil(len(dirs) * split_ratio)

    train_dir = data_dir + "/train"
    test_dir = data_dir + "/test"
    if not list(os.scandir(train_dir)) or not list(os.scandir(test_dir)):
        copy(dirs[pivot:], train_dir)
        copy(dirs[:pivot], test_dir)
    else:
        logging.warning('Data already split.')