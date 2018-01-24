#!/usr/bin/env bash

# Begin configuration.
nj=4
decode=true
# End configuration.

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

exp_dir=${1}
num_gaussians=${2}

steps/train_mono.sh --nj ${nj} --totgauss ${num_gaussians} data/train lang/base ${exp_dir}/mono

if ${decode}; then
    utils/mkgraph.sh lang/base ${exp_dir}/mono ${exp_dir}/mono/graph
    steps/decode.sh --nj ${nj} ${exp_dir}/mono/graph data/test ${exp_dir}/mono/decode
    steps/lmrescore_const_arpa.sh lang/base lang/rescore data/test ${exp_dir}/mono/decode ${exp_dir}/mono/rescore
fi