resource "aws_s3_bucket" "BUCKETNAME" {
   bucket = "BUCKETNAME-TEAMNAME" 
}

resource "aws_s3_bucket_ownership_controls" "BUCKETNAME" {
  bucket = aws_s3_bucket.BUCKETNAME.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "BUCKETNAME" {
  depends_on = [aws_s3_bucket_ownership_controls.BUCKETNAME]
  bucket     = aws_s3_bucket.BUCKETNAME.id
  acl        = "private"
}

output "BUCKETNAME" {
    value = aws_s3_bucket.BUCKETNAME.arn
}