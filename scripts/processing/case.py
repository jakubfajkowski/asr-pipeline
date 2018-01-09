#!/usr/bin/python3
import argparse
import sys

LOWERCASE = 'lowercase'
UPPERCASE = 'uppercase'


def parse_args():
    parser = argparse.ArgumentParser(description='filters characters that are out of whitelist')
    parser.add_argument('files', metavar='FILES', default='-', nargs='*')
    parser.add_argument('-d', '--delimiter', dest='delimiter', type=str, default='\t')
    parser.add_argument('-f', '--field', dest='field', type=int, default=1)
    case = parser.add_mutually_exclusive_group(required=True)
    case.add_argument('-l', '--lowercase', dest='case', action='store_const', const=LOWERCASE)
    case.add_argument('-u', '--uppercase', dest='case', action='store_const', const=UPPERCASE)
    return parser.parse_args()


def lowercase(files, delimiter='\t', field=1):
    for file in files:
        with sys.stdin if file == '-' else open(file) as f_in:
            for line in f_in:
                line = line.rstrip('\n').split(delimiter)
                line[field - 1] = line[field - 1].lower()
                line = delimiter.join(line)
                print(line)


def uppercase(files, delimiter='\t', field=1):
    for file in files:
        with sys.stdin if file == '-' else open(file) as f_in:
            for line in f_in:
                line = line.rstrip('\n').split(delimiter)
                line[field - 1] = line[field - 1].upper()
                line = delimiter.join(line)
                print(line)


def main():
    args = parse_args()
    if args.case == LOWERCASE:
        lowercase(args.files, args.delimiter, args.field)
    elif args.case == UPPERCASE:
        uppercase(args.files, args.delimiter, args.field)


if __name__ == '__main__':
    main()
