#!/usr/bin/env bash

words=${1}

tools/multilingual-g2p/g2p.sh -w "${words}" -l "$(echo ${lang} | cut -d '-' -f1)"