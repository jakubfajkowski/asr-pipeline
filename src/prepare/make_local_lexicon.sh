#!/usr/bin/env bash

data_dir=${1}

echo -e "<UNK>\tspn"
cat ${data_dir}/*/lexicon.txt | sort -u