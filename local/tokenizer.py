#!/usr/bin/python3

import fileinput
import re

from argparse import ArgumentParser, ArgumentTypeError
from nltk import word_tokenize

LANGUAGE_MAP = {
    'cz': 'czech',
    'da': 'danish',
    'nl': 'dutch',
    'en': 'english',
    'et': 'estonian',
    'fi': 'finnish',
    'fr': 'french',
    'de': 'german',
    'el': 'greek',
    'it': 'italian',
    'no': 'norwegian',
    'pl': 'polish',
    'pt': 'portuguese',
    'sl': 'slovene',
    'es': 'spanish',
    'sv': 'swedish',
    'tr': 'turkish'
}
LANGUAGE_PATTERN = '[a-z]{2}'


def parse_args():
    parser = ArgumentParser(description='a pipe tool to extract single words from sentences')
    parser.add_argument('locale', metavar='LOCALE', type=check_language)
    parser.add_argument('files', metavar='FILES', nargs='*', default='-')
    return parser.parse_args()


def check_language(locale):
    language_short = re.match(LANGUAGE_PATTERN, locale).group()
    if language_short not in LANGUAGE_MAP:
        raise ArgumentTypeError('"{}" is invalid or not supported locale.'.format(locale))
    return LANGUAGE_MAP[language_short]


def read_words(files, language):
    words = set()
    with fileinput.input(files) as f_in:
        for line in f_in:
            utterance = line.rstrip('\n')
            utterance_words = word_tokenize(utterance, language=language)
            words.update(set(utterance_words))
    return words


def print_words(words):
    for word in sorted(words):
        print(word)


def main():
    args = parse_args()
    words = read_words(args.files, args.locale)
    print_words(words)


if __name__ == '__main__':
    main()
