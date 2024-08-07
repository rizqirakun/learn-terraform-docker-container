provider "aws" {
  region = "ap-southeast-1"
}

# resource "aws_instance" "instance1" {
#   ami           = "ami-0497a974f8d5dcef8"
#   instance_type = "t2.micro"

#   tags = {
#     name = "my-demo-instance"
#   }
# }

# variable "BUCKET_NAME" {
#   type = string
# }

resource "random_string" "random" {
  length  = 12
  upper   = false
  numeric = false
  lower   = true
  special = false
}

locals {
  BUCKET_NAME = "cli-test-${random_string.random.result}"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = local.BUCKET_NAME
}

resource "aws_s3_bucket_ownership_controls" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "my_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.my_bucket,
    aws_s3_bucket_public_access_block.my_bucket,
  ]

  bucket = aws_s3_bucket.my_bucket.id
  acl    = "public-read"
}