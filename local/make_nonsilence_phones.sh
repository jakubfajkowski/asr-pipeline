#!/usr/bin/env bash

cat $@ | cut -f 2 | tr ' ' '\n' | sed "/^\s*$/d"|  sort -u