#!/usr/bin/env bash

lang=${1}
corpus=${2}

cat ${corpus} | local/processing/tokenizer.py ${lang}
