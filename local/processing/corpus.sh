#!/usr/bin/env bash

source path.sh

lang=${1}; shift
corpus_rules=${1}; shift

fix.py ${corpus_rules} | case.py -l | clean.py ${lang}
