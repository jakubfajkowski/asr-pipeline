#!/usr/bin/env bash

words=${1}

lang=$(echo ${corpus_lang} | cut -d '-' -f1)
tools/multilingual-g2p/g2p.sh -w "${words}" -l "${lang}"