#! /usr/bin/env python3
# Downloads a secret from AWS secrets manager and puts it into the
# specified output file

import argparse
import ast
import os

import boto3
from botocore.exceptions import ClientError


def get_secret(secret_name, secret_key):
    endpoint_url = "https://secretsmanager.eu-central-1.amazonaws.com"
    region_name = "eu-central-1"

    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name,
        endpoint_url=endpoint_url
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print("The requested secret " + secret_name + " was not found")
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            print("The request was invalid due to:", e)
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            print("The request had invalid params:", e)
    else:
        secret = ast.literal_eval(get_secret_value_response['SecretString'])
        return secret[secret_key]


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--name', action="store", required=True)
    parser.add_argument('--value', action="store", required=True)
    parser.add_argument('--output', action="store", required=True)
    args = parser.parse_args()

    if not os.path.exists(os.path.dirname(args.output)):
        os.makedirs(os.path.dirname(args.output))

    with open(args.output, 'w') as f:
        f.write(get_secret(args.name, args.value))
        print(f"pulled secret: {args.name}/{args.value}")
