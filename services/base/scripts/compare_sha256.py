#!/usr/bin/env python3

import argparse
import hashlib
import sys


def sha256_checksum(filename, block_size=65536):
    sha256 = hashlib.sha256()
    with open(filename, 'rb') as f:
        for block in iter(lambda: f.read(block_size), b''):
            sha256.update(block)
    return sha256.hexdigest()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--file', action="store", required=True)
    parser.add_argument('--expected', action="store", required=True)
    args = parser.parse_args()

    actual = sha256_checksum(args.file)
    assert actual == args.expected, \
        f'\nchecksums do not match.\nexpected: {args.expected}\ngot: {actual}'
