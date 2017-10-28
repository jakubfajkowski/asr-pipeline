#!/usr/bin/env bash

whitelist="a-zA-ZąĄćĆęĘłŁńŃóÓśŚźŹżŻ"
special=" \n"

tr -cd "${whitelist}${special}"