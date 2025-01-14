/**
 * A Terraform module that creates a tagged S3 bucket and an IAM user/key with access to the bucket
 */

# aws credentials
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# we need a service account user
resource "aws_iam_user" "user" {
  name = "srv_${var.bucket_name}"
}

# generate keys for service account user
resource "aws_iam_access_key" "user_keys" {
  user = "${aws_iam_user.user.name}"
}

# create an s3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.bucket_name}"
  force_destroy = "true"

  versioning {
    enabled = "${var.versioning}"
  }

  tags = {
    team          = "${var.tag_team}"
    application   = "${var.tag_application}"
    environment   = "${var.tag_environment}"
    contact-email = "${var.tag_contact-email}"
    customer      = "${var.tag_customer}"
  }

    lifecycle_rule {
      id                                     = "auto-delete-incomplete-after-x-days"
      prefix                                 = ""
      enabled                                = "${var.multipart_delete}"
      abort_incomplete_multipart_upload_days = "${var.multipart_days}"
    }
}

# grant user access to the bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.user.arn}"
      },
      "Action": [ "s3:*" ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
EOF
}
