# Kratix on Amazon Elastic Kubernetes Service (EKS)

Welcome to the repository for deploying Kratix on EKS.
These docs assume that
1. You have access to an AWS account and have permissions for S3 buckets and RDS instances.
2. You have created an S3 bucket you want Kratix to write to.

## Setting local variables

These manifests require permissions access and create resources in your AWS account.
You need the following environment variables set:

```
DIR_EXAMPLES

BUCKET_NAME
BUCKET_ENDPOINT
BUCKET_KEY_ID
BUCKET_ACCESS_KEY

RDS_KEY_ID
RDS_ACCESS_KEY
```

You may set `DIR_EXAMPLES` as:
```
export DIR_EXAMPLES=$(pwd)
```

`BUCKET_NAME` and `BUCKET_ENDPOINT` should be set to an existing S3 bucket, which Kratix will use as its StateStore.
For `BUCKET_KEY_ID` and `BUCKET_ACCESS_KEY`, please set to AWS credentials that have permission to read&write to S3 buckets.
For `RDS_KEY_ID` and `RDS_ACCESS_KEY`, please set to AWS credentials that have permission to create AWS RDS instances.

## Updating manifests

There are a number of manifests that require updating with the environment variable values.
Some of this data is sensitive. For that reason, the files have been added to .gitignore.
You should not include these if you push your changes to a remote repository.

```bash
mkdir -p ${DIR_EXAMPLES}/secrets && rm ${DIR_EXAMPLES}/secrets/**
sed \
    -e "s/RDS_KEY_ID/$RDS_KEY_ID/" \
    -e "s/RDS_ACCESS_KEY/$RDS_ACCESS_KEY/" \
    ${DIR_EXAMPLES}/secrets.template/bucket-secret.yaml > ${DIR_EXAMPLES}/secrets/bucket-secret.yaml

sed \
    -e "s/BUCKET_KEY_ID/$BUCKET_KEY_ID/" \
    -e "s/BUCKET_ACCESS_KEY/$BUCKET_ACCESS_KEY/" \
    ${DIR_EXAMPLES}/secrets.template/bucket-secret.yaml > ${DIR_EXAMPLES}/secrets/bucket-secret.yaml

sed \
    -e "s/BUCKET_KEY_ID/$BUCKET_KEY_ID/" \
    -e "s/BUCKET_ACCESS_KEY/$BUCKET_ACCESS_KEY/" \
    ${DIR_EXAMPLES}/secrets.template/bucketstatestore-secret.yaml > ${DIR_EXAMPLES}/secrets/bucketstatestore-secret.yaml

sed \
    -e "s/BUCKET_NAME/$BUCKET_NAME/" \
    -e "s/BUCKET_ENDPOINT/$BUCKET_ENDPOINT/" \
    ${DIR_EXAMPLES}/secrets.template/bucket.yaml > ${DIR_EXAMPLES}/secrets/bucket.yaml

sed \
    -e "s/BUCKET_NAME/$BUCKET_NAME/" \
    -e "s/BUCKET_ENDPOINT/$BUCKET_ENDPOINT/" \
    ${DIR_EXAMPLES}/secrets.template/bucketstatestore.yaml > ${DIR_EXAMPLES}/secrets/bucketstatestore.yaml
```