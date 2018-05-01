#! /usr/bin/env python

# Downloads all required secrets from AWS secrets manager and puts them into
# the 'secrets' directory on disk

import boto3
import ast
import os

from botocore.exceptions import ClientError

script_dir = os.path.dirname(os.path.realpath(__file__))


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
    os.makedirs(os.path.join(script_dir, 'secrets'))

    with open(os.path.join(script_dir, 'secrets', 'sealer-account'), 'a') as f:
        f.write(get_secret("circles-secrets", "sealer-account"))

    with open(os.path.join(script_dir, 'secrets', 'sealer-account-password'), 'a') as f:
        f.write(get_secret("circles-secrets", "sealer-account-password"))

    with open(os.path.join(script_dir, 'secrets', 'ws-secret'), 'a') as f:
        f.write(get_secret("circles-secrets", "ws-secret"))
