#!/usr/bin/env bash

source path.sh

lang=${1}; shift
files=$@

for file in ${files}; do
    cat ${file} | perl -pe 's/<s> //' | perl -pe 's/ <\/s>//' | scripts/processing/case.py -l -f 2 | scripts/processing/clean.py ${lang} -f 2
done