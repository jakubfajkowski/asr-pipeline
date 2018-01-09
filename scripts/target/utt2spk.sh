#!/usr/bin/env bash

source path.sh

for file in $@; do
    utterance_id=$(basename ${file} | scripts/processing/strip_extension.sh)
    speaker_id=$(basename $(dirname ${file}))
    echo -e "${utterance_id}\t${speaker_id}"
done