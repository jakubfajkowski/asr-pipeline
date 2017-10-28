#!/usr/bin/env bash

files=$@

for file in ${files}; do
    grep -Po "(?<=<s> ).+?(?= </s>)" ${file} | case.sh -l | filter_characters.sh
done