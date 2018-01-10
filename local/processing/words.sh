#!/usr/bin/env bash

source path.sh

lang=${1}; shift

tokenizer.py ${lang}
