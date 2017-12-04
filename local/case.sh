#!/usr/bin/env bash

if [ "${1}" == "-u" ]; then
    tr '[:lower:]' '[:upper:]'
elif [ "${1}" == "-l" ]; then
    tr '[:upper:]' '[:lower:]'
fi