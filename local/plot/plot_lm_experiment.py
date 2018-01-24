#!/usr/bin/python3
import argparse
import matplotlib.pyplot as plt
import numpy as np


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('experiment_dirs', metavar='EXPERIMENT_DIRS', nargs='+')
    return parser.parse_args()


def get_wer(best_wer_file):
    with open(best_wer_file) as f_in:
        wer_line = f_in.read()
        return float(wer_line.split(' ')[1])

def main():
    args = parse_args()

    groups = []
    no_rescorings = []
    rescoring_3s = []
    rescoring_4s = []
    for dir in args.experiment_dirs:
        group = '/'.join(dir.split('/')[:-2])
        no_rescoring = get_wer('{}/decode/scoring_kaldi/best_wer'.format(dir))
        rescoring_3 = get_wer('{}/rescore_3/scoring_kaldi/best_wer'.format(dir))
        rescoring_4 = get_wer('{}/rescore_4/scoring_kaldi/best_wer'.format(dir))

        groups.append(group)
        no_rescorings.append(no_rescoring)
        rescoring_3s.append(rescoring_3)
        rescoring_4s.append(rescoring_4)
        print(group, no_rescoring, rescoring_3, rescoring_4, sep='\t')

    N = len(groups)
    fig, ax = plt.subplots()
    ind = np.arange(N)  # the x locations for the groups
    width = 0.30  # the width of the bars
    p1 = ax.bar(ind, no_rescorings, width, color='red')
    p2 = ax.bar(ind + width, rescoring_3s, width, color='green')
    p3 = ax.bar(ind + 2 * width, rescoring_4s, width, color='blue')

    ax.set_ylabel('WER [%]')
    ax.set_xticks(ind + width)
    ax.set_xticklabels(groups, rotation='vertical')
    ax.legend((p1[0], p2[0], p3[0]), ('-', '3-gram', '4-gram'), loc=4)

    plt.show()




if __name__ == '__main__':
    main()
