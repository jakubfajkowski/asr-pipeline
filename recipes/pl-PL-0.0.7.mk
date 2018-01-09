lang        := pl-PL
version     := 0.0.7
ngram_order := 3

corpus_train := /home/${USER}/Documents/ASR/data/train
corpus_test  := /home/${USER}/Documents/ASR/data/test
corpus_local := /home/${USER}/Documents/ASR/data/local

# Available feature types: fbank, mfcc, plp.
feature_type := mfcc
model_type   := mono

hidden_states_number := 128
gaussians_number     := 1024
train_mmi_boost      := 0.05
