#!/usr/bin/env bash

source path.sh

lang=${1}; shift
files=$@

for file in ${files}; do
    cat ${file} | perl -pe 's/<s> //' | perl -pe 's/ <\/s>//' | case.py -l -f 2 | clean.py ${lang} -f 2
done