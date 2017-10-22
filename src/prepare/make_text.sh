#!/usr/bin/env bash

files=${1}

for file in ${files}; do
    cat ${file} | perl -pe 's/<s> //' | perl -pe 's/ <\/s>//'
done