#!/usr/bin/env bash

source path.sh

lang=${1}; shift

scripts/processing/tokenizer.py ${lang}
