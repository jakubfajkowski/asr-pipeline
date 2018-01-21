#!/usr/bin/env bash

# Begin configuration.
nj=4
decode=true
# End configuration.

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

exp_dir=${1}
num_leaves=${2}
num_gaussians=${3}

if ! [ -d ${exp_dir}/tri4-ali ]; then
    steps/align_fmllr.sh --nj ${nj} --use-graphs true data/train lang/base ${exp_dir}/tri4 ${exp_dir}/tri4-ali
fi

if ! [ -d ${exp_dir}/tri4-ubm ]; then
    steps/train_ubm.sh --nj ${nj} ${num_gaussians} data/train lang/base ${exp_dir}/tri4-ali ${exp_dir}/tri4-ubm
fi

steps/train_sgmm2.sh ${num_leaves} ${num_gaussians} data/train lang/base ${exp_dir}/tri4-ali ${exp_dir}/tri4-ubm/final.ubm ${exp_dir}/sgmm2

if ${decode}; then
    utils/mkgraph.sh lang/base ${exp_dir}/sgmm2 ${exp_dir}/sgmm2/graph
    steps/decode_sgmm2.sh --nj ${nj} --transform-dir ${exp_dir}/tri4/decode ${exp_dir}/sgmm2/graph data/test ${exp_dir}/sgmm2/decode
    steps/lmrescore.sh --mode 1 lang/base lang/rescore data/test ${exp_dir}/sgmm2/decode ${exp_dir}/sgmm2/rescore
fi
