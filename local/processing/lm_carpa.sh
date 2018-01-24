#!/usr/bin/env bash

source path.sh

words=${1}; shift
lm_arpa=${1}; shift

bos=$(grep "<s>" ${words} | cut -f 2 -d " ")
eos=$(grep "</s>" ${words} | cut -f 2 -d " ")

arpa-to-const-arpa --bos-symbol=${bos} --eos-symbol=${eos} <(map_arpa_lm.pl ${words} < ${lm_arpa}) -