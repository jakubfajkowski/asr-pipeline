export RECIPES_ROOT="./recipes"
export BUILDS_ROOT="./builds"
export TOOLS_ROOT="../tools"
export KALDI_ROOT="/home/${USER}/kaldi"

# Setting paths to useful tools
PATH="$(find ${TOOLS_ROOT} -type d -printf "%p:"):${PATH}"
PATH="${KALDI_ROOT}/src/bin:${PATH}"
PATH="${KALDI_ROOT}/src/featbin/:${PATH}"
PATH="${KALDI_ROOT}/src/fgmmbin/:${PATH}"
PATH="${KALDI_ROOT}/src/fstbin/:${PATH}"
PATH="${KALDI_ROOT}/src/gmmbin/:${PATH}"
PATH="${KALDI_ROOT}/src/latbin/:${PATH}"
PATH="${KALDI_ROOT}/src/lmbin/:${PATH}"
PATH="${KALDI_ROOT}/src/online2bin/:${PATH}"
PATH="${KALDI_ROOT}/src/sgmm2bin/:${PATH}"
PATH="${KALDI_ROOT}/tools/openfst/bin:${PATH}"
PATH="${PWD}/utils:${PATH}"
PATH="${PWD}:${PATH}"
export PATH

# Enable SRILM
source "${KALDI_ROOT}/tools/env.sh"

# Variable needed for proper data sorting
export LC_ALL=C.UTF-8