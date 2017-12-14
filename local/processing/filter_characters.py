#!/usr/bin/python3
import argparse
import re
import sys

FILTERS = {
    'pl-PL': r'[^ a-zA-ZąĄćĆęĘłŁńŃóÓśŚźŹżŻ]'
}

SEPARATORS = '[ -]'


def parse_args():
    parser = argparse.ArgumentParser(description='filters characters that are out of whitelist')
    parser.add_argument('locale', metavar='LOCALE', default='pl-PL')
    parser.add_argument('files', metavar='FILES', default='-', nargs='*')
    parser.add_argument('-d', '--delimiter', dest='delimiter', type=str, default='\t')
    parser.add_argument('-f', '--field', dest='field', type=int, default=1)
    return parser.parse_args()


def filter_characters(files, locale, delimiter='\t', field=1):
    separator_pattern = re.compile(SEPARATORS)
    filter_pattern = re.compile(FILTERS[locale])
    for file in files:
        with sys.stdin if file == '-' else open(file) as f_in:
            for line in f_in:
                line = line.rstrip('\n').split(delimiter)
                line[field - 1] = separator_pattern.sub(' ', line[field - 1])
                line[field - 1] = filter_pattern.sub('', line[field - 1])
                line = delimiter.join(line)
                print(line)


def main():
    args = parse_args()
    filter_characters(args.files, args.locale, args.delimiter, args.field)


if __name__ == '__main__':
    main()
