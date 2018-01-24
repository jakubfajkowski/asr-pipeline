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

if ! [ -d ${exp_dir}/tri2-ali ]; then
    steps/align_si.sh --nj ${nj} --use-graphs true data/train lang/base ${exp_dir}/tri2 ${exp_dir}/tri2-ali
fi

steps/train_lda_mllt.sh  ${num_leaves} ${num_gaussians} data/train lang/base ${exp_dir}/tri2-ali ${exp_dir}/tri3

if ${decode}; then
    utils/mkgraph.sh lang/base ${exp_dir}/tri3 ${exp_dir}/tri3/graph
    steps/decode.sh --nj ${nj} ${exp_dir}/tri3/graph data/test ${exp_dir}/tri3/decode
    steps/lmrescore_const_arpa.sh lang/base lang/rescore data/test ${exp_dir}/tri3/decode ${exp_dir}/tri3/rescore
fi
