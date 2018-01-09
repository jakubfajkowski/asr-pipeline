#!/usr/bin/python3
import argparse
import logging
import random


def parse_args():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    parser.add_argument('-f', '--file', dest='files', action='append', nargs=2, metavar=('CORPUS', 'RATIO'), default=[])
    group.add_argument('-b', '--bytes', dest='bytes', type=int, default=0)
    group.add_argument('-c', '--chars', dest='chars', type=int, default=0)
    group.add_argument('-l', '--lines', dest='lines', type=int, default=0)
    group.add_argument('-w', '--words', dest='words', type=int, default=0)
    return parser.parse_args()


def normalize(files):
    normalized = []
    ratio_sum = sum([float(i[1]) for i in files])
    for corpus, ratio in files:
        normalized.append((corpus, float(ratio) / ratio_sum))
    return normalized


def mix(files, max_count, count_method):
    count = 0
    results = []
    count_method_unit = count_method.__name__.replace('count_', '')
    logging.info('Selecting ~{} {}'.format(max_count, count_method_unit))
    for corpus, ratio in files:
        max_corpus_count = int(max_count * ratio)
        logging.info('Selecting ~{} {} from {}'.format(max_corpus_count, count_method_unit, corpus))
        with open(corpus, encoding='UTF-8') as c_in:
            lines, corpus_count = random_lines(c_in, max_corpus_count, count_method)
            logging.info('Selected {} {} from {}'.format(corpus_count, count_method_unit, corpus))
            for line in lines:
                print(line.rstrip('\n'))
            results.append((corpus, corpus_count))
            count += corpus_count
    logging.info('Selected ~{} {}'.format(count, count_method_unit))
    return results


def random_lines(file, max_count, count_method):
    count = 0
    selected = []
    for i, line in enumerate(file):
        if count < max_count:
            selected.append(line)
            count += count_method(line)
        else:
            m = random.randint(0, i)
            if m < len(selected):
                count -= count_method(selected[m])
                selected[m] = line
                count += count_method(selected[m])
    return selected, count


def count_bytes(line):
    return len(line.encode('UTF-8'))


def count_chars(line):
    return len(line)


def count_lines(line):
    return 1 if line else 0


def count_words(line):
    return len(line.split(' '))


def main():
    logging.basicConfig(format='[%(asctime)s][%(levelname)s] %(name)s: %(message)s', level=logging.INFO)
    args = parse_args()
    files = normalize(args.files)
    logging.info('Desired ratio: {}'.format(','.join([str(f) for f in files])))
    if args.bytes:
        files = mix(files, args.bytes, count_bytes)
    elif args.chars:
        files = mix(files, args.chars, count_chars)
    elif args.lines:
        files = mix(files, args.lines, count_lines)
    elif args.words:
        files = mix(files, args.words, count_words)
    files = normalize(files)
    logging.info('Achieved ratio: {}'.format(','.join([str(f) for f in files])))


if __name__ == '__main__':
    main()
