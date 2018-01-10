#!/usr/bin/env bash

source path.sh

extension='.wav'

for file in $@; do
    utterance_id=$(basename ${file} ${extension})
    speaker_id=$(basename $(dirname ${file}))
    echo -e "${utterance_id}\t${speaker_id}"
done