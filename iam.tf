// -----------------------------------------------------------------------------
// Instance Profiles / Roles
// -----------------------------------------------------------------------------

variable "default_role" {
  type = "string"
  default = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

// sealer

resource "aws_iam_instance_profile" "sealer" {
  name = "circles-sealer"
  role = "${aws_iam_role.sealer.name}"
}

resource "aws_iam_role" "sealer" {
  name = "circles-sealer"
  assume_role_policy = "${var.default_role}"
}

// ethstats

resource "aws_iam_instance_profile" "ethstats" {
  name = "circles-ethstats"
  role = "${aws_iam_role.ethstats.name}"
}

resource "aws_iam_role" "ethstats" {
  name = "circles-ethstats"
  assume_role_policy = "${var.default_role}"
}

// rpc

resource "aws_iam_instance_profile" "rpc" {
  name = "circles-rpc"
  role = "${aws_iam_role.rpc.name}"
}

resource "aws_iam_role" "rpc" {
  name = "circles-rpc"
  assume_role_policy = "${var.default_role}"
}

// bootnode

resource "aws_iam_instance_profile" "bootnode" {
  name = "circles-bootnode"
  role = "${aws_iam_role.bootnode.name}"
}

resource "aws_iam_role" "bootnode" {
  name = "circles-bootnode"
  assume_role_policy = "${var.default_role}"
}

// -----------------------------------------------------------------------------
// Policies
// -----------------------------------------------------------------------------

// Read Sealer Account

resource "aws_iam_policy_attachment" "sealer_account" {
  name       = "circles-sealer-account"
  roles      = ["${aws_iam_role.sealer.name}"]
  policy_arn = "${aws_iam_policy.sealer_account.arn}"
}

resource "aws_iam_policy" "sealer_account" {
  name = "circles-sealer-account"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-sealer-account-bim5lZ"
        }
    ]
}
EOF
}

// Read ws_secret For Ethstats

resource "aws_iam_policy_attachment" "ethstats_ws_secret" {
  name       = "circles-ethstats-ws-secret"
  roles      = ["${aws_iam_role.sealer.name}", "${aws_iam_role.ethstats.name}", "${aws_iam_role.rpc.name}"]
  policy_arn = "${aws_iam_policy.ethstats_ws_secret.arn}"
}

resource "aws_iam_policy" "ethstats_ws_secret" {
  name = "circles-ethstats-ws-secret"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-ws-secret-nhzYC3"
        }
    ]
}
EOF
}

// Read Bootnode Key

resource "aws_iam_policy_attachment" "bootnode_key" {
  name       = "circles-bootnode-key"
  roles      = ["${aws_iam_role.bootnode.name}"]
  policy_arn = "${aws_iam_policy.bootnode_key.arn}"
}

resource "aws_iam_policy" "bootnode_key" {
  name = "circles-bootnode-key"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-bootnode-key-13R79U"
        }
    ]
}
EOF
}

// Write Cloudwatch Logs

resource "aws_iam_policy_attachment" "circles_logging" {
  name       = "circles-logging"
  roles      = ["${aws_iam_role.sealer.name}", "${aws_iam_role.bootnode.name}", "${aws_iam_role.ethstats.name}", "${aws_iam_role.rpc.name}"]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
