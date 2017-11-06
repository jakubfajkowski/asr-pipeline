#!/usr/bin/env bash

source $(which log.sh)
source $(which arguments.sh)

SCRIPT_FILE="$(basename ${0})"
SCRIPT_NAME="$(echo ${SCRIPT_FILE} | strip_extension.sh)"

register_optional_argument "--cmd" "cmd" "utils/parallel/run.pl" "how to run jobs"
register_optional_argument "--jobs" "jobs" "4" "number of parallel jobs"
register_optional_argument "--log-dir" "log_dir" "." "logging directory"
register_optional_argument "--config" "config" "conf/mfcc.conf" "config passed to compute-mfcc-feats"
register_positional_argument "data_dir" ""
parse_arguments $@

wav_dir=$(realpath ${data_dir}/wav)
mfcc_dir=$(realpath ${data_dir}/mfcc)

mkdir -p ${wav_dir}
mkdir -p ${mfcc_dir}

check_requirements.sh ${data_dir}/wav.scp ${mfcc_config}
utils/split_scp.sh ${data_dir}/wav.scp ${jobs}

# add ,p to the input rspecifier so that we can just skip over
# utterances that have bad wave data.
$cmd JOB=1:${jobs} ${log_dir}/${SCRIPT_NAME}.JOB.log                       \
    compute-mfcc-feats --config=${config}                                  \
                       "scp,p:${wav_dir}/wav.JOB.scp"                      \
                       "ark:-" \|                                          \
    copy-feats "ark:-"                                                     \
               "ark,scp:${mfcc_dir}/mfcc.JOB.ark,${mfcc_dir}/mfcc.JOB.scp"

cat ${mfcc_dir}/mfcc.*.scp > ${data_dir}/feats.scp