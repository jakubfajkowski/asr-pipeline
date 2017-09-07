#!/usr/bin/env bash

files=${1}

for file in ${files}; do
    cut -f2 ${file}
done