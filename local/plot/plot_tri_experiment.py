#!/usr/bin/python3
import argparse
import glob
from matplotlib import cm
import matplotlib.pyplot as plt
from matplotlib.ticker import LinearLocator, FormatStrFormatter
from mpl_toolkits.mplot3d import Axes3D
import numpy as np
from scipy.optimize import curve_fit
                   

def parse_args():
    parser = argparse.ArgumentParser()
    return parser.parse_args()


def get_wer(best_wer_file):
    with open(best_wer_file) as f_in:
        wer_line = f_in.read()
        return float(wer_line.split(' ')[1])

def main():
    args = parse_args()

    labels = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192]

    fig = plt.figure()
    ax = fig.gca(projection='3d')

    # Make data.
    N = len(labels)
    X = np.arange(N)
    Y = np.arange(N)
    X, Y = np.meshgrid(X, Y)
    
    Z = np.zeros((N, N))
    for x in range(N):
        for y in range(N):
            Z[x, y] = get_wer('{}-{}/decode/scoring_kaldi/best_wer'.format(labels[x], labels[y]))
    print(Z)

    # Plot the surface.
    surf = ax.plot_surface(X, Y, Z, cmap=cm.coolwarm,
                                   linewidth=0, antialiased=False)

    # Customize the z axis.
    ax.zaxis.set_major_locator(LinearLocator(10))
    ax.zaxis.set_major_formatter(FormatStrFormatter('%.02f'))

    ax.set_xlabel('Liczba liści drzewa klasteryzującego')
    ax.set_ylabel('Liczba rozkładów Gaussa')
    ax.set_zlabel('WER [%]')

    ax.set_xticks(np.arange(N))
    ax.set_yticks(np.arange(N))

    strings = [str(l) for l in labels]
    ax.set_xticklabels(strings, rotation=-15,
                       verticalalignment='baseline',
                       horizontalalignment='left')
    ax.set_yticklabels(strings, rotation=15,
                       verticalalignment='baseline',
                       horizontalalignment='right')
    plt.legend()

    plt.show()




if __name__ == '__main__':
    main()
