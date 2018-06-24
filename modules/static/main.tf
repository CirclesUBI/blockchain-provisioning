variable service_name {}

# -----------------------------------------------------------------------------------

locals {
  genesis_json      = "genesis.json"
  static_nodes_json = "static-nodes.json"
  get_secret_py     = "get_secret.py"
}

# -----------------------------------------------------------------------------------

output "genesis_url" {
  value = "${aws_s3_bucket.this.bucket_domain_name}/${local.genesis_json}"
}

output "static_nodes_url" {
  value = "${aws_s3_bucket.this.bucket_domain_name}/${local.static_nodes_json}"
}

output "get_secret_url" {
  value = "${aws_s3_bucket.this.bucket_domain_name}/${local.get_secret_py}"
}

# -----------------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket        = "circles-blockchain-static-${var.service_name}"
  force_destroy = true
  acl           = "public-read"
}

# -----------------------------------------------------------------------------------

resource "aws_s3_bucket_object" "genesis_json" {
  key    = "${local.genesis_json}"
  source = "${path.module}/${local.genesis_json}"
  bucket = "${aws_s3_bucket.this.id}"
  acl    = "public-read"
}

resource "aws_s3_bucket_object" "static_nodes_json" {
  key    = "${local.static_nodes_json}"
  source = "${path.module}/${local.static_nodes_json}"
  bucket = "${aws_s3_bucket.this.id}"
  acl    = "public-read"
}

resource "aws_s3_bucket_object" "get_secret_py" {
  key    = "${local.get_secret_py}"
  source = "${path.module}/${local.get_secret_py}"
  bucket = "${aws_s3_bucket.this.id}"
  acl    = "public-read"
}

# -----------------------------------------------------------------------------------

