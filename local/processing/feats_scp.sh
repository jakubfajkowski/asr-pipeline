#!/usr/bin/env bash

source path.sh

data_dir=${1}; shift

for dir in ${data_dir}/*; do
    case ${feature_type} in
        fbank)
            steps/make_fbank.sh --nj $(JOBS) ${dir} ${dir}/log ${dir}
            ;;
        mfcc)
            steps/make_mfcc.sh --nj $(JOBS) ${dir} ${dir}/log ${dir}
            ;;
        plp)
            steps/make_plp.sh --nj $(JOBS) ${dir} ${dir}/log ${dir}
            ;;
        esac

    steps/compute_cmvn_stats.sh ${dir} ${dir}/log ${dir}
    utils/fix_data_dir.sh ${dir}
done