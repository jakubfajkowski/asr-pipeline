#!/usr/bin/env bash

words=${1}
lang=${2}

g2p.sh -w "${words}" -l "$(echo ${lang} | cut -d '-' -f1)"