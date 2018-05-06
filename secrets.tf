resource "aws_iam_instance_profile" "circles" {
  name = "circles-secrets"
  role = "${aws_iam_role.circles.name}"
}

resource "aws_iam_role" "circles" {
  name = "circles-secrets"

  assume_role_policy = <<EOF
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

resource "aws_iam_policy_attachment" "circles" {
  name       = "circles-secrets"
  roles      = ["${aws_iam_role.circles.name}"]
  policy_arn = "${aws_iam_policy.circles.arn}"
}

resource "aws_iam_policy" "circles" {
  name = "circles-secrets"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:574150460280:secret:circles-secrets-zr9x30"
        }
    ]
}
EOF
}
