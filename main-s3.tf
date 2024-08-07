# terraform variable
variable "region" { default = "ap-southeast-1" }

# default aws provider region
provider "aws" {
  region = var.region
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

# generate random string
resource "random_string" "random" {
  length  = 12
  upper   = false
  numeric = false
  lower   = true
  special = false
}

# local variable
locals {
  BUCKET_NAME = "cli-test-${random_string.random.result}"
  CONTENT_TYPE = {
   "js" = "application/json"
   "txt" = "text/plain"
   "html" = "text/html"
   "css"  = "text/css"
  }
}

# create a new bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = local.BUCKET_NAME
}

# create ownership bucket owner
resource "aws_s3_bucket_ownership_controls" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# change access of bucket options
resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# activate acl to public-read
resource "aws_s3_bucket_acl" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_ownership_controls.my_bucket,
    aws_s3_bucket_public_access_block.my_bucket,
  ]
}

# create s3 policy
data "aws_iam_policy_document" "s3_my_bucket_policy" {
  policy_id = "s3_my_bucket_policy"

  statement {
    actions = [
      "s3:GetObject"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.my_bucket.arn}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    sid = "S3IconsBucketPublicAccess"
  }
}

# assign bucket policy
resource "aws_s3_bucket_policy" "my_bucket" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.s3_my_bucket_policy.json
}

# resource "aws_s3_object" "object1" {
#   for_each = fileset("assets/", "*")
#   bucket = aws_s3_bucket.my_bucket.id
#   key = "uploads/${each.value}"
#   source = "assets/${each.value}"
# }

# upload a file from local
resource "aws_s3_object" "object1" {
  for_each = fileset("assets/", "*")
  bucket = aws_s3_bucket.my_bucket.id
  key    = "uploads/${each.value}"
  source = "assets/${each.value}"
  etag   = filemd5("assets/${each.value}")
  content_type = lookup(local.CONTENT_TYPE, regex("\\.[^.]+$", each.value), "text/plain")
  content_disposition = "inline"
  depends_on = [ aws_s3_bucket_policy.my_bucket ]
}

resource "aws_s3_object" "object2" {
  for_each = fileset("assets/", "**/*")
  bucket = aws_s3_bucket.my_bucket.id
  key    = "uploads/${each.value}"
  source = "assets/${each.value}"
  etag   = filemd5("assets/${each.value}")
  content_type = lookup(local.CONTENT_TYPE, regex("\\.[^.]+$", each.value), "text/plain")
  content_disposition = "inline"
  depends_on = [ aws_s3_bucket_policy.my_bucket ]
}

# create a folder
resource "aws_s3_object" "object3" {
  bucket = aws_s3_bucket.my_bucket.id
  key    = "demo1/directory2/"
}