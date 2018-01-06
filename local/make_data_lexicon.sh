#!/usr/bin/env bash

lang=${1}; shift
lexicon_rules=${1}; shift

local/processing/g2p.sh ${lang} $@ | local/processing/fix.py -f 2 ${lexicon_rules}