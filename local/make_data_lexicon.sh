#!/usr/bin/env bash

words=${1}
lang=${2}

local/processing/g2p.sh ${lang} ${words}