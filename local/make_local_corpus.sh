#!/usr/bin/env bash

lang=${1}; shift
files=$@

cat $@ | local/processing/case.py -l | local/processing/clean.py ${lang}