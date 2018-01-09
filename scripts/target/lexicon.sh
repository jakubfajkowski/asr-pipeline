#!/usr/bin/env bash

source path.sh

lang=${1}; shift
lexicon_rules=${1}; shift

scripts/processing/g2p.sh ${lang} | scripts/processing/fix.py -f 2 ${lexicon_rules}