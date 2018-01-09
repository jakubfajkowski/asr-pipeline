#!/usr/bin/env bash

source path.sh

lang=${1}; shift
lexicon_rules=${1}; shift

echo -e "<UNK>\tSPN"
scripts/target/lexicon.sh ${lang} ${lexicon_rules} | sort -u - $@