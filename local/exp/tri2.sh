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

if ! [ -d ${exp_dir}/tri1-ali ]; then
    steps/align_si.sh --nj ${nj} --use-graphs true data/train lang/base ${exp_dir}/tri1 ${exp_dir}/tri1-ali
fi

steps/train_deltas.sh ${num_leaves} ${num_gaussians} data/train lang/base ${exp_dir}/tri1-ali ${exp_dir}/tri2

if ${decode}; then
    utils/mkgraph.sh lang/base ${exp_dir}/tri2 ${exp_dir}/tri2/graph
    steps/decode.sh --nj ${nj} ${exp_dir}/tri2/graph data/test ${exp_dir}/tri2/decode
    steps/lmrescore.sh --mode 1 lang/base lang/rescore data/test ${exp_dir}/tri2/decode ${exp_dir}/tri2/rescore
fi