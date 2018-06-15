#! /usr/bin/env python3

# Installs geth (including all support tools) to /usr/bin

import argparse
from distutils.dir_util import copy_tree
import functools
import hashlib
import os
import tarfile
import tempfile
import urllib.request


def md5sum(filename):
    with open(filename, mode="rb") as f:
        d = hashlib.md5()
        for buf in iter(functools.partial(f.read, 128), b""):
            d.update(buf)
    return d.hexdigest()


def extract(archive, output_dir):
    tar = tarfile.open(archive)
    tar.extractall(path=output_dir)
    tar.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", action="store", required=True)
    parser.add_argument("--commit", action="store", required=True)
    parser.add_argument("--md5", action="store", required=True)
    args = parser.parse_args()

    release = f"geth-alltools-linux-amd64-{args.version}-{args.commit}"
    url = f"https://gethstore.blob.core.windows.net/builds/{release}.tar.gz"

    tar, headers = urllib.request.urlretrieve(url)
    assert md5sum(tar) == args.md5

    with tempfile.TemporaryDirectory() as output_dir:
        extract(tar, output_dir)
        copy_tree(os.path.join(output_dir, release), "/usr/bin/")
