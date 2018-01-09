#!/usr/bin/env bash

source path.sh

lang=${1}; shift
corpus_rules=${1}; shift

scripts/processing/fix.py ${corpus_rules} | scripts/processing/case.py -l | scripts/processing/clean.py ${lang}
