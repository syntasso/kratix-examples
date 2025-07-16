# Kratix on Amazon Elastic Kubernetes Service (EKS)

Welcome to the repository for deploying Kratix on EKS.

These manifests are designed to be used alongside the [video demo](https://youtu.be/PSm_C4-dIvM)
and related [docs](https://docs.kratix.io/main/guides/installing-kratix-EKS).

These docs assume that
1. You have access to an AWS account and have permissions for S3 buckets and RDS instances.
2. You have created an S3 bucket you want Kratix to write to.

## Setting local variables

These manifests require permissions access and create resources in your AWS account, you will need the following environment variables set. Where possible, sensible defaults have been set:

```bash
export DIR_EXAMPLES=$(pwd)
export BUCKET_NAME=
export BUCKET_ENDPOINT=
export BUCKET_KEY_ID=
export BUCKET_ACCESS_KEY=
export RDS_KEY_ID=
export RDS_ACCESS_KEY=
```

`BUCKET_NAME` and `BUCKET_ENDPOINT` should be set to an existing S3 bucket, which Kratix will use as its StateStore.
For `BUCKET_KEY_ID` and `BUCKET_ACCESS_KEY`, please set to AWS credentials that have permission to read&write to S3 buckets.
For `RDS_KEY_ID` and `RDS_ACCESS_KEY`, please set to AWS credentials that have permission to create AWS RDS instances.

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
