#!/usr/bin/env bash

silence_phones=${1}; shift

grep -v -f ${silence_phones} $@ | cut -f 2 | tr ' ' '\n' | sed "/^\s*$/d"|  sort -u