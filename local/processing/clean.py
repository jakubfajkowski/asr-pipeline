#!/usr/bin/python3
import argparse
import re
import sys
from abc import ABC, abstractmethod


class Cleaner(ABC):
    @abstractmethod
    def apply(self, text):
        pass


class NonBreakingSpaceCleaner(Cleaner):
    NON_BREAKING_SPACE = '\u00A0'

    def apply(self, text):
        return text.replace(NonBreakingSpaceCleaner.NON_BREAKING_SPACE, ' ')


class CharacterCleaner(Cleaner):
    LOCALES_TO_PATTERNS = {
        'pl-PL': r'[^a-zA-ZąĄćĆęĘłŁńŃóÓśŚźŹżŻ -]'
    }

    def __init__(self, locale):
        self.regex = re.compile(CharacterCleaner.LOCALES_TO_PATTERNS[locale])

    def apply(self, text):
        return self.regex.sub(' ', text)


class SeparatorCleaner(Cleaner):
    SEPARATORS = ' -'
    PATTERN = '[' + SEPARATORS + ']+'

    def __init__(self):
        self.regex = re.compile(SeparatorCleaner.PATTERN)

    def apply(self, text):
        return self.regex.sub(' ', text).strip(SeparatorCleaner.SEPARATORS)


class TyposCleaner(Cleaner):
    MAX_IN_ROW = 3

    def apply(self, text):
        cleaned = ''
        prev_letter = ''
        buffer = ''
        for curr_letter in text:
            if curr_letter != prev_letter:
                cleaned += buffer if len(buffer) <= TyposCleaner.MAX_IN_ROW else prev_letter
                buffer = ''
            buffer += curr_letter
            prev_letter = curr_letter
        cleaned += buffer if len(buffer) < TyposCleaner.MAX_IN_ROW else prev_letter
        return cleaned

def parse_args():
    parser = argparse.ArgumentParser(description='filters characters that are out of whitelist')
    parser.add_argument('locale', metavar='LOCALE', default='pl-PL')
    parser.add_argument('files', metavar='FILES', default='-', nargs='*')
    parser.add_argument('-d', '--delimiter', dest='delimiter', type=str, default='\t')
    parser.add_argument('-f', '--field', dest='field', type=int, default=1)
    return parser.parse_args()


def clean(files, locale, delimiter='\t', field=1):
    cleaners = [
        NonBreakingSpaceCleaner(),
        CharacterCleaner(locale),
        SeparatorCleaner(),
        TyposCleaner()
    ]

    for file in files:
        with sys.stdin if file == '-' else open(file) as f_in:
            for line in f_in:
                line = line.rstrip('\n').split(delimiter)
                for cleaner in cleaners:
                    line[field - 1] = cleaner.apply(line[field - 1])
                line = delimiter.join(line)
                print(line)


def main():
    args = parse_args()
    clean(args.files, args.locale, args.delimiter, args.field)


if __name__ == '__main__':
    main()
