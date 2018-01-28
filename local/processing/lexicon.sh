#!/usr/bin/env bash

source path.sh

lang=${1}; shift
lexicon_rules=${1}; shift

g2p.sh ${lang} | fix.py -f 2 ${lexicon_rules} | tr '|' ' '