#!/usr/bin/env bash

source path.sh

lang=${1}; shift

scripts/target/words.sh ${lang} | sort -u - $@
