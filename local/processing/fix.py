#!/usr/bin/python3
import argparse
import copy
import re
import sys
from abc import ABC, abstractmethod


class Trie():
    class Node():
        def __init__(self, value=None):
            self._children = dict()
            self._value = value

        @property
        def value(self):
            return self._value

        def insert(self, key, value, default=None):
            if len(key) > 0:
                if key[0] not in self._children:
                    self._children[key[0]] = Trie.Node(value=copy.deepcopy(default))
                self._children[key[0]].insert(key[1:], value, default)
            else:
                self._value = value

        def get(self, key, longest_match=False):
            if len(key) > 0:
                if key[0] not in self._children:
                    if longest_match:
                        return self._value
                    else:
                        raise KeyError()

                value = self._children[key[0]].get(key[1:], longest_match)
                return value if value else self._value
            else:
                return self._value

        def __contains__(self, key):
            if len(key) > 0:
                if key[0] not in self._children:
                    return False
                return self._children[key[0]].__contains__(key[1:])
            else:
                return True

        def is_leaf(self, key):
            if len(key) > 0:
                if key[0] not in self._children:
                    raise KeyError()
                return self._children[key[0]].is_leaf(key[1:])
            else:
                return not self._children

    def __init__(self, default=None, longest_match=False):
        self._default = default
        self._longest_match = longest_match
        self._root = Trie.Node(default)

    def __setitem__(self, key, value):
        self._root.insert(key, value, self._default)

    def __getitem__(self, key):
        return self._root.get(key, self._longest_match)

    def __contains__(self, key):
        return self._root.__contains__(key)

    def is_leaf(self, key):
        return self._root.is_leaf(key)


class Fixer(ABC):
    @abstractmethod
    def apply(self, text):
        pass


class WindowFixer(Fixer):
    SPLIT_PATTERN = re.compile(r'(\W+)')
    JOIN_PATTERN = ''

    def __init__(self, rules_file):
        self._trie = Trie(default=[])
        self._max_window_size = 0
        with open(rules_file) as f_in:
            for line in f_in:
                line = line.rstrip('\n')
                wrong, correct = list(map(WindowFixer.SPLIT_PATTERN.split, line.split('\t')))
                self._max_window_size = max(len(wrong), self._max_window_size)
                self._trie[wrong] = correct

    def apply(self, text):
        wrong_words = WindowFixer.SPLIT_PATTERN.split(text)
        correct_words = []
        potentially_correct_words = []

        window_begin = 0
        window_size = min(self._max_window_size, len(wrong_words) - window_begin)
        while window_begin < len(wrong_words):
            window_end = window_begin + window_size
            if window_end > window_begin:
                current_wrong_words = wrong_words[window_begin:window_end]

                if current_wrong_words in self._trie:
                    if self._trie.is_leaf(current_wrong_words):
                        correct_words += self._trie[current_wrong_words]
                        window_begin += window_size
                        window_size = min(self._max_window_size, len(wrong_words) - window_begin)
                        window_size -= 1
                    else:
                        potentially_correct_words = self._trie[current_wrong_words]
                        window_size -= 1
                else:
                    potentially_correct_words = current_wrong_words
                    window_size -= 1
            else:
                correct_words += potentially_correct_words
                window_begin += 1
                window_size = min(self._max_window_size, len(wrong_words) - window_begin)

        return WindowFixer.JOIN_PATTERN.join(correct_words)


class LongestMatchFixer(Fixer):
    SPLIT_PATTERN = re.compile(r'(\W+)')
    JOIN_PATTERN = ''

    def __init__(self, rules_file):
        self._trie = Trie(longest_match=True)
        with open(rules_file) as f_in:
            for line in f_in:
                line = line.rstrip('\n')
                wrong, correct = list(map(WindowFixer.SPLIT_PATTERN.split, line.split('\t')))
                self._trie[wrong] = (wrong, correct)

    def apply(self, text):
        wrong_words = WindowFixer.SPLIT_PATTERN.split(text)
        correct_words = []

        i = 0
        while i < len(wrong_words):
            result = self._trie[wrong_words[i:]]
            if result:
                current_wrong_words, current_correct_words = result
                i += len(current_wrong_words)
            else:
                current_correct_words = wrong_words[i]
                i += 1
            correct_words += current_correct_words

        return WindowFixer.JOIN_PATTERN.join(correct_words)


def parse_args():
    parser = argparse.ArgumentParser(description='filters characters that are out of whitelist')
    parser.add_argument('rules_file', metavar='RULES_FILE')
    parser.add_argument('files', metavar='FILES', default='-', nargs='*')
    parser.add_argument('-d', '--delimiter', dest='delimiter', type=str, default='\t')
    parser.add_argument('-f', '--field', dest='field', type=int, default=1)
    return parser.parse_args()


def clean(files, rules_file, delimiter='\t', field=1):
    fixer = LongestMatchFixer(rules_file)

    for file in files:
        with sys.stdin if file == '-' else open(file) as f_in:
            for line in f_in:
                line = line.rstrip('\n').split(delimiter)
                line[field - 1] = fixer.apply(line[field - 1])
                line = delimiter.join(line)
                print(line)


def main():
    args = parse_args()
    clean(args.files, args.rules_file, args.delimiter, args.field)


if __name__ == '__main__':
    main()
