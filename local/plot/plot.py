#!/usr/bin/python3
import argparse
import glob
from collections import OrderedDict

import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('metric', metavar='METRIC')
    parser.add_argument('-l', '--labels', dest='labels', nargs='+', required=True)
    parser.add_argument('-m', '--markers', dest='markers', nargs='+')
    parser.add_argument('-s', '--suppress-legend', dest='suppress_legend', action='store_true')
    parser.add_argument('-t', '--ticks', dest='ticks', nargs='+', required=True)
    parser.add_argument('-v', '--value-files', dest='value_files', action='append', nargs='+', required=True)
    parser.add_argument('-x', '--x-label', dest='x_label', default='')
    return parser.parse_args()


def get_value(value_location, metric):
    if metric == 'wer':
        with open(value_location) as f_in:
            line = f_in.read()
        return float(line.split(' ')[1])
    else:
        log_files = glob.glob(value_location + '/decode.*.log')
        sum = 0
        count = len(log_files)
        for log_file in log_files:
            with open(log_file) as f_in:
                for line in f_in:
                    if 'real-time factor' in line:
                        sum += float(line.split('real-time factor was ')[1].split(' (note: this cannot be less than one.)')[0])
        return sum / count


def get_y_label(metric):
    if metric == 'wer':
        return 'WER [%]'
    elif metric == 'rtf':
        return 'RTF'

def main():
    args = parse_args()

    values = OrderedDict()
    print('label', '\t'.join(args.ticks), sep='\t')
    for i, label in enumerate(args.labels):
        values[label] = []
        for value_file in args.value_files[i]:
            values[label].append(get_value(value_file, args.metric))
        print(label, '\t'.join([str(value) for value in values[label]]), sep='\t')

    N = len(args.ticks)
    x = np.arange(N)

    for i, pair in enumerate(values.items()):
        label, y = pair
        if not args.markers:
            plt.plot(x, y, label=label)
        else:
            plt.plot(x, y, args.markers[i], label=label)

    plt.xticks(x, args.ticks, rotation='vertical')
    plt.xlabel(args.x_label)
    plt.ylabel(get_y_label(args.metric))
    if not args.suppress_legend:
        plt.legend()
    plt.show()

if __name__ == '__main__':
    main()
