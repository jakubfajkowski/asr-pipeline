#!/usr/bin/env bash

lang=${1}; shift
files=$@

for file in ${files}; do
    cut -f 2 ${file} | local/processing/case.py -l | local/processing/filter_characters.py ${lang}
done