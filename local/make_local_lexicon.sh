#!/usr/bin/env bash

lexicon_rules=${1}; shift

echo -e "<UNK>\tSPN"
./local/processing/fix.py -f 2 ${lexicon_rules} $@ | sort -u