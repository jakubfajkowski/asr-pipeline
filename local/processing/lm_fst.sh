#!/usr/bin/env bash

source path.sh

words=${1}; shift
lm_arpa=${1}; shift

arpa2fst --disambig-symbol="#0" --read-symbol-table=${words} ${lm_arpa} -