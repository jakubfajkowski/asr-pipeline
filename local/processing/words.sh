#!/usr/bin/env bash

source path.sh

lang=${1}; shift

tokenize.py ${lang}
