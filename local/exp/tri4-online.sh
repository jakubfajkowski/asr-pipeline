#!/usr/bin/env bash

# Begin configuration.
nj=5
decode=true
# End configuration.

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;

exp_dir=${1}

if ! [ -d exp/tri4/graph ]; then
    utils/mkgraph.sh lang/base exp/tri4 exp/tri4/graph
fi

steps/online/prepare_online_decoding.sh --feature-type ${feature_type} data/train lang/base exp/tri4 exp/tri4-fmmi/final.mdl exp/tri4-online
steps/online/decode.sh exp/tri4/graph data/test exp/tri4-online/decode
steps/lmrescore_const_arpa.sh lang/base lang/rescore data/test exp/tri4-online/decode exp/tri4-online/rescore