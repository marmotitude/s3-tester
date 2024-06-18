resource "aws_s3_bucket" "first_bucket" {
  bucket_prefix = "test-tofu-"
}

resource "aws_s3_object" "first_bucket_objects" {
  for_each = tomap({
    file1 = "./main.tf"
    file2 = "./resources.tf"
  })
  bucket = aws_s3_bucket.first_bucket.id
  key    = each.value
  source = each.value
}

