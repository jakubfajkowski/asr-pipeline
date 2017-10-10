#!/usr/bin/env bash
export LC_ALL=C
find -name "lexicon.txt" -exec cut -f 2 {}  \; | tr ' ' '\n' | sed "/^\s*$/d"|  sort -u