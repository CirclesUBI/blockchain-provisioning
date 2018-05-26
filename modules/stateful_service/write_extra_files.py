#! /usr/bin/env python3

import argparse
import base64
import json
from os import path, makedirs

# Expects a base64 encoded json mapping of filenames to base64 econded
# file content. each file will be written to /services/<filename>


def write_files(prefix, extra_files):
    decoded = json.loads(base64.decodebytes(extra_files.encode('ascii')))

    print(f"write_files: decoded_json: {decoded}")

    for specifier in decoded['extra_files']:
        output_path = path.join(prefix, specifier['filename'])
        with open(output_path, "w") as file:
            decoded_file = base64.decodebytes(
                specifier['content'].encode('ascii')).decode('ascii')
            file.write(decoded_file)
            print(f"write_files: wrote:\n ${decoded_file}\n to: {output_path}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('extra_files', action="store")
    args = parser.parse_args()

    print(f"write_files: processing: {args.extra_files}")

    write_files('./service', args.extra_files)
