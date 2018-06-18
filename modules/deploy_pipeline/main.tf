variable "dockerfile" {}

variable "branch" {
  default = "production"
}

variable "ecs_service_name" {}
variable "ecs_cluster_name" {}
variable "ecr_repository_url" {}

# ----------------------------------------------------------------------------------------------
# Buildspec
# ----------------------------------------------------------------------------------------------

data "template_file" "buildspec" {
  template = "${file("${path.module}/buildspec.yaml")}"

  vars {
    dockerfile         = "${var.dockerfile}"
    ecs_service_name   = "${var.ecs_service_name}"
    ecr_repository_url = "${var.ecr_repository_url}"
  }
}

# ----------------------------------------------------------------------------------------------
# Codepipeline
# ----------------------------------------------------------------------------------------------

resource "aws_codepipeline" "this" {
  name     = "${var.ecs_service_name}"
  role_arn = "${aws_iam_role.codepipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.artifact_storage.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        Owner  = "CirclesUBI"
        Repo   = "blockchain-provisioning"
        Branch = "${var.branch}"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      version          = "1"
      output_artifacts = ["build_output"]

      configuration {
        ProjectName = "${aws_codebuild_project.this.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration {
        ClusterName = "${var.ecs_cluster_name}"
        ServiceName = "${var.ecs_service_name}"
        FileName    = "images.json"
      }
    }
  }
}

# ----------------------------------------------------------------------------------------------
# Codebuild project
# ----------------------------------------------------------------------------------------------

resource "aws_codebuild_project" "this" {
  name         = "circles-${var.ecs_service_name}"
  service_role = "${aws_iam_role.codebuild.arn}"

  source = {
    type      = "CODEPIPELINE"
    buildspec = "${data.template_file.buildspec.rendered}"
  }

  artifacts = {
    type = "CODEPIPELINE"
  }

  environment = {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/docker:17.09.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}

# ----------------------------------------------------------------------------------------------
# Artifact Storage
# ----------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "artifact_storage" {
  bucket        = "${var.ecs_service_name}-codepipeline-artifact-storage"
  acl           = "private"
  force_destroy = true
}

# ----------------------------------------------------------------------------------------------
# Codepipeline IAM
# ----------------------------------------------------------------------------------------------

resource "aws_iam_role" "codepipeline" {
  name = "${var.ecs_service_name}-codepipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.ecs_service_name}-codepipeline"
  role = "${aws_iam_role.codepipeline.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:putObject"
      ],
      "Resource": [
        "${aws_s3_bucket.artifact_storage.arn}",
        "${aws_s3_bucket.artifact_storage.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:Describe*",
        "autoscaling:UpdateAutoScalingGroup",
        "cloudformation:CreateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStack*",
        "cloudformation:UpdateStack",
        "cloudwatch:GetMetricStatistics",
        "ec2:Describe*",
        "elasticloadbalancing:*",
        "ecs:*",
        "events:DescribeRule",
        "events:DeleteRule",
        "events:ListRuleNamesByTarget",
        "events:ListTargetsByRule",
        "events:PutRule",
        "events:PutTargets",
        "events:RemoveTargets",
        "iam:ListInstanceProfiles",
        "iam:ListRoles",
        "iam:PassRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# ----------------------------------------------------------------------------------------------
# Codebuild IAM
# ----------------------------------------------------------------------------------------------

resource "aws_iam_role" "codebuild" {
  name = "${var.ecs_service_name}-codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.ecs_service_name}-codebuild"
  role = "${aws_iam_role.codebuild.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:putObject"
      ],
      "Resource": [
        "${aws_s3_bucket.artifact_storage.arn}",
        "${aws_s3_bucket.artifact_storage.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
      ],
      "Resource": ["*"]
    }
  ]
}
POLICY
}
