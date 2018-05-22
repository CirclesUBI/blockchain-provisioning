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

// sealer1

resource "aws_iam_instance_profile" "sealer1" {
  name = "circles-sealer-1"
  role = "${aws_iam_role.sealer1.name}"
}

resource "aws_iam_role" "sealer1" {
  name = "circles-sealer-1"
  assume_role_policy = "${var.default_role}"
}

// sealer2

resource "aws_iam_instance_profile" "sealer2" {
  name = "circles-sealer-2"
  role = "${aws_iam_role.sealer2.name}"
}

resource "aws_iam_role" "sealer2" {
  name = "circles-sealer-2"
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

// Read Sealer 1 Account

resource "aws_iam_policy_attachment" "sealer1_account" {
  name       = "circles-sealer-account"
  roles      = ["${aws_iam_role.sealer1.name}"]
  policy_arn = "${aws_iam_policy.sealer1_account.arn}"
}

resource "aws_iam_policy" "sealer1_account" {
  name = "circles-sealer-1-account"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-sealer-1-kEDcJJ"
        }
    ]
}
EOF
}

// Read Sealer 2 Account

resource "aws_iam_policy_attachment" "sealer2_account" {
  name       = "circles-sealer-account"
  roles      = ["${aws_iam_role.sealer2.name}"]
  policy_arn = "${aws_iam_policy.sealer2_account.arn}"
}

resource "aws_iam_policy" "sealer2_account" {
  name = "circles-sealer-2-account"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-sealer-2-mSJnoU"
        }
    ]
}
EOF
}

// Read ws_secret For Ethstats

resource "aws_iam_policy_attachment" "ethstats_ws_secret" {
  name       = "circles-ethstats-ws-secret"
  roles      = ["${aws_iam_role.sealer1.name}", "${aws_iam_role.sealer2.name}", "${aws_iam_role.ethstats.name}", "${aws_iam_role.rpc.name}"]
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
  roles      = ["${aws_iam_role.sealer1.name}", "${aws_iam_role.sealer2.name}", "${aws_iam_role.bootnode.name}", "${aws_iam_role.ethstats.name}", "${aws_iam_role.rpc.name}"]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
