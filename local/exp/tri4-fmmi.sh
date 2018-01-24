#!/usr/bin/env bash

# Begin configuration.
nj=4
decode=true
learning_rate=0.001
# End configuration.

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

exp_dir=${1}
num_gaussians=${2}
boost=${3}
iterations=8

if ! [ -d ${exp_dir}/tri4-ali ]; then
    steps/align_fmllr.sh --nj ${nj} --use-graphs true data/train lang/base ${exp_dir}/tri4 ${exp_dir}/tri4-ali
fi

if ! [ -d ${exp_dir}/tri4-denlats ]; then
    steps/make_denlats.sh --nj ${nj} --transform-dir ${exp_dir}/tri4-ali data/train lang/base ${exp_dir}/tri4 ${exp_dir}/tri4-denlats
fi

if ! [ -d ${exp_dir}/tri4-diag-ubm ]; then
    steps/train_diag_ubm.sh --nj ${nj} ${num_gaussians} data/train lang/base ${exp_dir}/tri4-ali ${exp_dir}/tri4-diag-ubm
fi

steps/train_mmi_fmmi.sh --learning-rate ${learning_rate} --boost ${boost} \
                        data/train lang/base ${exp_dir}/tri4-ali ${exp_dir}/tri4-diag-ubm ${exp_dir}/tri4-denlats ${exp_dir}/tri4-fmmi

if ${decode}; then
    if ! [ -d ${exp_dir}/tri4/graph ]; then
        utils/mkgraph.sh lang/base ${exp_dir}/tri4 ${exp_dir}/tri4/graph
    fi

    for iter in $(seq 0 $((iterations - 1))); do
        steps/decode_fmmi.sh --nj ${nj} --iter ${iter} --transform-dir ${exp_dir}/tri4/decode \
                             ${exp_dir}/tri4/graph data/test ${exp_dir}/tri4-fmmi/decode-${iter}
        steps/lmrescore_const_arpa.sh lang/base lang/rescore data/test ${exp_dir}/tri4-fmmi/decode-${iter} ${exp_dir}/tri4-fmmi/rescore-${iter}
    done
fi
