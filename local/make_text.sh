#!/usr/bin/env bash

lang=${1}; shift
files=$@

for file in ${files}; do
    cat ${file} | perl -pe 's/<s> //' | perl -pe 's/ <\/s>//' | local/processing/case.py -l -f 2 | local/processing/clean.py ${lang} -f 2
done