import argparse
import boto3
import botocore
from retry import retry
import time

# Attaches an ENI and an EBS volume to an EC2 instance
# Need to retry as sometimes there is a race condition where the resources
# have not been dettached from the old instance when the new instance is coming up

boto3.setup_default_session(region_name="eu-central-1")


def snapshot_volume(instance_id, volume_id, service_name):
    ec2 = boto3.client("ec2")
    print(f"attach_resources: snapshotting {volume_id}")
    snap = ec2.create_snapshot(
        Description=f"{volume_id} - {instance_id}",
        VolumeId=volume_id,
        TagSpecifications=[
            {
                "ResourceType": "snapshot",
                "Tags": [{"Key": "Name", "Value": f"circles-{service_name}"}],
            }
        ],
    )
    assert snap["State"] != "error"


@retry(exceptions=botocore.exceptions.ClientError, tries=5, delay=1, backoff=2)
def attach_volume(instance_id, volume_id):
    ec2 = boto3.resource("ec2")
    volume = ec2.Volume(args.volume_id)

    print(f"attach_resources: attaching volume {volume_id} to {instance_id}")
    volume.attach_to_instance(Device="/dev/xvdb", InstanceId=instance_id)
    time.sleep(15)  # wait for volume to attach
    print("attach_resources: volume attached")


@retry(exceptions=botocore.exceptions.ClientError, tries=5, delay=1, backoff=2)
def attach_interface(instance_id, interface_id):
    ec2 = boto3.resource("ec2")
    interface = ec2.NetworkInterface(args.interface_id)

    print(f"attach_resources: attaching interface {interface_id} to {instance_id}")
    interface.attach(DeviceIndex=1, InstanceId=instance_id)
    time.sleep(15)  # wait for interface to attach
    print("attach_resources: interface attached")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--interface_id", action="store", required=True)
    parser.add_argument("--instance_id", action="store", required=True)
    parser.add_argument("--volume_id", action="store", required=True)
    parser.add_argument("--service_name", action="store", required=True)
    args = parser.parse_args()

    snapshot_volume(args.instance_id, args.volume_id, args.service_name)
    attach_volume(args.instance_id, args.volume_id)
    attach_interface(args.instance_id, args.interface_id)
