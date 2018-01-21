#!/usr/bin/env bash

# Begin configuration.
nj=4
decode=true
type=dnn
# End configuration.

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

exp_dir=${1}

if ! [ -d ${exp_dir}/tri4-ali ]; then
    steps/align_fmllr.sh --nj ${nj} --use-graphs true data/train lang/base ${exp_dir}/tri4 ${exp_dir}/tri4-ali
fi

steps/train_nnet.sh data/train data/train lang/base ${exp_dir}/tri4-ali ${exp_dir}/tri4-ali ${exp_dir}/nnet-${type}

if ${decode}; then
    steps/decode_nnet.sh --nj ${nj} ${exp_dir}/tri4/graph data/test ${exp_dir}/nnet-${type}/decode
    steps/lmrescore.sh --mode 1 lang/base lang/rescore data/test ${exp_dir}/nnet-${type}/decode ${exp_dir}/nnet-${type}/rescore
fi