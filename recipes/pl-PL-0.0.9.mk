lang        := pl-PL
version     := 0.0.9
ngram_order := 3

corpus_train := /home/${USER}/Documents/ASR/data/train
corpus_test  := /home/${USER}/Documents/ASR/data/test
corpus_local := /home/${USER}/Documents/ASR/data/local

# Available feature types: fbank, mfcc, plp.
feature_type := mfcc
model_type   := online-tri4

hidden_states_number := 256
gaussians_number     := 2048
train_mmi_boost      := 0.05
