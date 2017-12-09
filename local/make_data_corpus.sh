#!/usr/bin/env bash

files=$@

for file in ${files}; do
    cut -f 2 ${file} | local/processing/case.sh -l | local/processing/filter_characters.sh
done