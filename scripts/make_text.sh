#!/usr/bin/env bash

files=${1}

for file in ${files}; do
    cat ${file}
done