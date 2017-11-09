#!/usr/bin/env bash

lang=${1}
corpus=${2}

cat ${corpus} | tokenizer.py ${lang}
