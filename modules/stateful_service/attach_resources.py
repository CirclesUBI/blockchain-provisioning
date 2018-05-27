import argparse
import boto3
import botocore
from retry import retry
import time

# Attaches an ENI and an EBS volume to an EC2 instance
# Need to retry as sometimes there is a race condition where the resources
# have not been dettached from the old instance when the new instance is coming up

boto3.setup_default_session(region_name='eu-central-1')


@retry(exceptions=botocore.exceptions.ClientError, tries=10, delay=1, backoff=2)
def attach_interface(instance_id, interface_id):
    ec2 = boto3.resource('ec2')
    interface = ec2.NetworkInterface(args.interface_id)

    print(f"attach_resources: trying to attach interface {interface_id} to {instance_id}")
    interface.attach(DeviceIndex=1, InstanceId=instance_id)
    time.sleep(15)  # wait for interface to attach
    print("attach_resources: interface attached")


@retry(exceptions=botocore.exceptions.ClientError, tries=10, delay=1, backoff=2)
def attach_volume(instance_id, volume_id):
    ec2 = boto3.resource('ec2')
    volume = ec2.Volume(args.volume_id)

    print(f"attach_resources: trying to attach volume {volume_id} to {instance_id}")
    volume.attach_to_instance(Device='/dev/xvdb', InstanceId=instance_id)
    time.sleep(15)  # wait for volume to attach
    print("attach_resources: volume attached")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--interface_id', action="store", required=True)
    parser.add_argument('--instance_id', action="store", required=True)
    parser.add_argument('--volume_id', action="store", required=True)
    args = parser.parse_args()

    attach_interface(args.instance_id, args.interface_id)
    attach_volume(args.instance_id, args.volume_id)
