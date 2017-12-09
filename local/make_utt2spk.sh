#!/usr/bin/env bash

data_dir=${1}

for file in ${data_dir}/*/*.wav; do
    utterance_id=$(basename ${file} | local/processing/strip_extension.sh)
    speaker_id=$(basename $(dirname ${file}))
    echo -e "${utterance_id}\t${speaker_id}"
done