#!/usr/bin/env bash

# Begin configuration.
nj=5
decode=true
# End configuration.

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

exp_dir=${1}
num_leaves=${2}
num_gaussians=${3}

if ! [ -d ${exp_dir}/mono-ali ]; then
    steps/align_si.sh --nj ${nj} data/train lang/base ${exp_dir}/mono ${exp_dir}/mono-ali
fi

steps/train_deltas.sh ${num_leaves} ${num_gaussians} data/train lang/base ${exp_dir}/mono-ali ${exp_dir}/tri1

if ${decode}; then
    utils/mkgraph.sh lang/base ${exp_dir}/tri1 ${exp_dir}/tri1/graph
    steps/decode.sh --nj ${nj} ${exp_dir}/tri1/graph data/test ${exp_dir}/tri1/decode
    steps/lmrescore_const_arpa.sh lang/base lang/rescore data/test ${exp_dir}/tri1/decode ${exp_dir}/tri1/rescore
fi