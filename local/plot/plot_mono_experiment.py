#!/usr/bin/python3
import argparse
import glob
import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit


def get_wer(best_wer_file):
    with open(best_wer_file) as f_in:
        wer_line = f_in.read()
        return float(wer_line.split(' ')[1])


def trend_curve(x, a, b, c):
    return a * x ** 2 + b * x + c


def main():
    wers = []
    wers_best = []
    for num in range(500, 5500, 100):
        best_wer_file = '{}/decode/scoring_kaldi/best_wer'.format(num)
        wers.append((num, get_wer(best_wer_file)))
        if num in [2100, 2600, 3700]:
            wers_best.append((num, get_wer(best_wer_file)))

    X_labels, Y = map(list, zip(*wers))
    X_labels_best, Y_best = map(list, zip(*wers_best))

    N = len(wers)
    X = np.arange(N)  # the x locations for the groups
    X_best = [X_labels.index(x_label) for x_label in X_labels_best]
    plt.plot(X, Y, 'bo')
    plt.plot(X_best, Y_best, 'ro')

    popt, pcov = curve_fit(trend_curve, X, Y)
    xx = np.linspace(0, N, 1000)
    yy = trend_curve(xx, *popt)
    plt.plot(xx, yy, 'k--')

    plt.ylabel('WER [%]')
    plt.xlabel('Liczba rozkładów Gaussa')
    plt.xticks(X, X_labels, rotation='vertical')

    plt.show()




if __name__ == '__main__':
    main()
