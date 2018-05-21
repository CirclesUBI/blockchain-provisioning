resource "aws_iam_instance_profile" "circles" {
  name = "circles"
  role = "${aws_iam_role.circles.name}"
}

resource "aws_iam_role" "circles" {
  name = "circles"

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

resource "aws_iam_policy_attachment" "circles_secrets" {
  name       = "circles-secrets"
  roles      = ["${aws_iam_role.circles.name}"]
  policy_arn = "${aws_iam_policy.circles_secrets.arn}"
}

resource "aws_iam_policy" "circles_secrets" {
  name = "circles-secrets"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "arn:aws:secretsmanager:eu-central-1:183869895864:secret:circles-secrets-pf58gy"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "circles_logging" {
  name       = "circles-logging"
  roles      = ["${aws_iam_role.circles.name}"]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
