#!/usr/bin/env bash

# Begin configuration.
nj=4
decode=true
# End configuration.

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

exp_dir=${1}
boost=${2}
iterations=${3}

if ! [ -d ${exp_dir}/tri4-ali ]; then
    steps/align_fmllr.sh --nj ${nj} --use-graphs true data/train lang/base ${exp_dir}/tri4 ${exp_dir}/tri4-ali
fi

if ! [ -d ${exp_dir}/tri4-denlats ]; then
    steps/make_denlats.sh --nj ${nj} --transform-dir ${exp_dir}/tri4-ali data/train lang/base ${exp_dir}/tri4 ${exp_dir}/tri4-denlats
fi

steps/train_mmi.sh --boost ${boost} --num-iters ${iterations} \
                   data/train lang/base ${exp_dir}/tri4-ali ${exp_dir}/tri4-denlats ${exp_dir}/tri4-mmi

if ${decode}; then
    if ! [ -d ${exp_dir}/tri4/graph ]; then
        utils/mkgraph.sh lang/base ${exp_dir}/tri4 ${exp_dir}/tri4/graph
    fi

    for iter in $(seq 0 $((iterations - 1))); do
        steps/decode.sh --nj ${nj} --iter ${iter} --transform-dir ${exp_dir}/tri4/decode \
                        ${exp_dir}/tri4/graph data/test ${exp_dir}/tri4-mmi/decode-${iter}
        steps/lmrescore_const_arpa.sh lang/base lang/rescore data/test ${exp_dir}/tri4-mmi/decode-${iter} ${exp_dir}/tri4-mmi/rescore-${iter}
    done
fi
