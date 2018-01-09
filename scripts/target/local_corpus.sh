#!/usr/bin/env bash

source path.sh

lang=${1}; shift
corpus_rules=${1}; shift

scripts/target/corpus.sh ${lang} ${corpus_rules} | cat - $@