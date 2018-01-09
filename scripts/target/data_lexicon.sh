#!/usr/bin/env bash

source path.sh

lang=${1}; shift
lexicon_rules=${1}; shift

cat $@ | lexicon.sh ${lang} ${lexicon_rules}