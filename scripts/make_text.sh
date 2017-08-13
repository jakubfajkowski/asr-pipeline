#!/usr/bin/env bash

files=${1}

for file in ${files}; do
    speaker=$(basename $(dirname ${file}))
    sed -e "s/^/${speaker}_/g" ${file}
done