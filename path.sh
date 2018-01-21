export TOOLS_ROOT="/home/${USER}/Projects/asr-system/asr-tools"
export KALDI_ROOT="/home/${USER}/Projects/kaldi"

# Setting paths to useful tools
PATH="${PWD}:${PATH}"
PATH="${PWD}/utils:${PATH}"
PATH="${TOOLS_ROOT}/scripts:${PATH}"
PATH="${KALDI_ROOT}/src/bin:${PATH}"
PATH="${KALDI_ROOT}/src/ivectorbin/:${PATH}"
PATH="${KALDI_ROOT}/src/featbin/:${PATH}"
PATH="${KALDI_ROOT}/src/fgmmbin/:${PATH}"
PATH="${KALDI_ROOT}/src/fstbin/:${PATH}"
PATH="${KALDI_ROOT}/src/gmmbin/:${PATH}"
PATH="${KALDI_ROOT}/src/latbin/:${PATH}"
PATH="${KALDI_ROOT}/src/lmbin/:${PATH}"
PATH="${KALDI_ROOT}/src/online2bin/:${PATH}"
PATH="${KALDI_ROOT}/src/sgmm2bin/:${PATH}"
PATH="${KALDI_ROOT}/src/nnetbin/:${PATH}"
PATH="${KALDI_ROOT}/src/nnet2bin/:${PATH}"
PATH="${KALDI_ROOT}/src/nnet3bin/:${PATH}"
PATH="${KALDI_ROOT}/tools/openfst/bin:${PATH}"
export PATH

# Enable SRILM
. "${KALDI_ROOT}/tools/env.sh"

# Variable needed for proper data sorting
export LC_ALL=C.UTF-8
