#!/usr/bin/env bash

files=${1}

for file in ${files}; do
    grep -Po "(?<=<s> ).+?(?= </s>)" ${file}
done