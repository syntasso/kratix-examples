# Kratix on Amazon Elastic Kubernetes Service (EKS)

Kratix runs on all Kubernetes services including Amazon Elastic Kubernetes Service (EKS). There are three key components to a Kratix installation:
1. Kratix platform orchestrator
1. A Git or S3 storage backend for declarative code
1. Infrastructure provider to make resources

While all three components are key to the success of a scalable enterprise platform orchestrator, Kratix maintains loose coupling allowing each to be hosted in the same or different providers including air-gapped on-premise environments.

This repository provides scripts to set up an S3 storage backend in AWS. These scripts are not intended for production without personal review. Should you want to discuss production grade deployments, reach out to the creators of Kratix, [Syntasso](https://syntasso.io/).

Before continuing please confirm the following pre-requisites:
1. You already have a Kratix installed.
    _(To install Kratix in AWS follow these [docs](https://docs.kratix.io/main/guides/installing-kratix-EKS) or this [video demo](https://youtu.be/PSm_C4-dIvM))_
1. You have access to an AWS account and have permissions to manage S3 buckets.
1. You have created an S3 bucket you want Kratix to write to _(instructions to create a bucket are included below if needed)_

## Setting local variables

These manifests require permissions access and create resources in your AWS account, you will need the following environment variables set. Where possible, sensible defaults have been set:

```bash
export DIR_EXAMPLES=$(pwd)
export BUCKET_NAME="kratix-$(whoami)-${RANDOM}"
export BUCKET_REGION="us-east-1"
export BUCKET_ENDPOINT=s3.${BUCKET_REGION}.amazonaws.com
export IAM_USER=${BUCKET_NAME}
```

If you need to create a bucket, you can use the following commands or refer to the [AWS documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html):

```bash
aws s3api create-bucket --bucket ${BUCKET_NAME} --region ${BUCKET_REGION} --no-cli-pager
```

If you need to create a service account with access to manage S3 buckets, you can use the following:

```bash
aws iam create-user --user-name ${IAM_USER} --no-cli-pager
aws iam attach-user-policy --user-name ${IAM_USER} --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --no-cli-pager 
eval $(aws iam create-access-key --user-name ${IAM_USER} --output text --no-cli-pager --query 'AccessKey.[AccessKeyId,SecretAccessKey]' | \
    awk '{print "export BUCKET_KEY_ID=\"" $1 "\"\nexport BUCKET_SECRET_ACCESS_KEY=\"" $2 "\""}')
```

Else, if you have created these already through the AWS documentation, set the following environment variables:

```bash
export BUCKET_KEY_ID=
export BUCKET_SECRET_ACCESS_KEY=
```


## Updating manifests

There are a number of manifests that require updating with the environment variable values.
Some of this data is sensitive. For that reason, the files have been added to
`.gitignore`. You should _not_ include these if you push your changes to a remote repository.

To create these secrets use:
```bash
./generate-secrets
```

### Configuring Kratix

Once the secrets are generated you can apply them to your cluster with a single command:
```bash
kubectl apply -f secrets/
```

These secrets are used by the gitops config that should be applied next using:
```bash
kubectl apply -f config/
```

To verify everything is working as expected, you should see the namespace `kratix-worker-system` appear after a minute or two.

Please see Kratix docs to further debug the connection if this does not appear.

## Build your platform with Kratix

You can use any of the Promises in the [Kratix Marketplace](https://docs.kratix.io/marketplace) or any custom Promises. We recommend that you can get started with the Cloud SQL promises found [here](https://github.com/syntasso/kratix-marketplace/tree/main/sql).
