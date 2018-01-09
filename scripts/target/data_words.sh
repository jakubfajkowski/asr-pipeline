#!/usr/bin/env bash

source path.sh

lang=${1}; shift

cat $@ | scripts/target/words.sh ${lang}
