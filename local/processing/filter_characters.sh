#!/usr/bin/env bash

delimiters="-"
whitelist="a-zA-ZąĄćĆęĘłŁńŃóÓśŚźŹżŻ"
special=" \n"

tr "${delimiters}" " " | tr -cd "${whitelist}${special}"