#!/usr/bin/env bash

files=$@

for file in ${files}; do
    cut -f 2 ${file} | case.sh -l | filter_characters.sh
done