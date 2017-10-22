#!/usr/bin/env bash

data_dir=${1}

cat ${data_dir}/*/lexicon.txt | cut -f 2 | tr ' ' '\n' | sed "/^\s*$/d"|  sort -u