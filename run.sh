#!/usr/bin/env bash

set -e

builds_dir=~/Builds
improve=false
corpora_dir=~/Corpora
corpora=empty
feature_type=mfcc
jobs=5
lang='pl-PL'
decode=false
workspace=''

source path.sh
source utils/parse_options.sh

export improve
export feature_type
export jobs
export lang

if [ -z ${workspace} ]; then
    local/log.sh -ent "You must specify workspace"
    exit 1
fi

local/log.sh -int "Copying repository to workspace: ${builds_dir}/${workspace}"
    mkdir -p ${builds_dir}/${workspace}
    cp -r * ${builds_dir}/${workspace}
    cd ${builds_dir}/${workspace}

local/log.sh -int "Creating build directories"
    mkdir -p data
    mkdir -p lang
    mkdir -p exp

local/log.sh -int "Copying corpora"
    cp -r ${corpora_dir}/${corpora}/data .

local/log.sh -int "Preparing data"
    for data_sub_dir in data/train data/test; do
        local/prepare_data.sh data/local ${data_sub_dir}
    done

local/log.sh -int "Preparing data/local"
    local/prepare_local.sh data/local

local/log.sh -int "Preparing lang"
    local/prepare_lang.sh "fst" 2 data/local lang/base
    local/prepare_lang.sh "carpa" 3 data/local lang/rescore

local/log.sh -int "Training monophone model."
    local/exp/mono.sh --decode ${decode} exp 2600

local/log.sh -int "Training triphone model (deltas)."
    local/exp/tri1.sh --decode ${decode} exp 256 2048

local/log.sh -int "Training triphone model (deltas and delta-deltas)."
    local/exp/tri2.sh --decode ${decode} exp 256 2048

local/log.sh -int "Training triphone model (LDA and MLLT)."
    local/exp/tri3.sh --decode ${decode} exp 256 2048

local/log.sh -int "Training triphone model (SAT)."
    local/exp/tri4.sh --decode ${decode} exp 256 2048

local/log.sh -int "Training triphone model (FMMI)."
    local/exp/tri4-fmmi.sh --decode ${decode} exp 256

local/log.sh -int "Preparing and evaluating final model."
    local/exp/tri4-online.sh --decode ${decode} exp
