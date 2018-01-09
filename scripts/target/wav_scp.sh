#!/usr/bin/env bash

source path.sh

readonly extension='.wav'

files=$@

for file in ${files}; do
    utterance_id=$(basename ${file} ${extension})
    absolute_path=$(realpath ${file})
    echo -e "${utterance_id}\t${absolute_path}"
done