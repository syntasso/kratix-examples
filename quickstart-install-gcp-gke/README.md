# Kratix on Google Kubernetes Engine (GKE)

Welcome to the repository for deploying Kratix on GKE.

These manifests are designed to be used alongside the [video demo](https://www.youtube.com/watch?v=Zkh3FIGMsds).

These docs assume:
1. You have the `gcloud` CLI installed and are currently logged in
1. You have created a GCP bucket you want Kratix to write to _(instructions to create a bucket are included below if needed)_
1. The infrastructure used and created require additional hardening before use in production

> [!TIP]
> Note that this Promise does not require you to be running Kratix on a Google Kubernetes Engine (GKE) cluster.
>
> If you would like to learn how to deploy Kratix to GKE, please follow these [docs](https://docs.kratix.io/main/guides/installing-kratix-GKE) to get started.

## Setting local variables

Given these manifests require permissions to both your Google Cloud Platform
(GCP) account, you will need the following environment variables set. Where possible,
sensible defaults have been set:

```bash
export DIR_EXAMPLES=$(pwd)
export DIR_GCLOUD_CONFIG=~/.config/gcloud
export BUCKET_NAME="kratix-$(whoami)-${RANDOM}"
export BUCKET_ACCESS_KEY=
export BUCKET_SECRET_KEY=
```

If you need to create a bucket, you can use the following commands or refer to the [GCP documentation](https://cloud.google.com/storage/docs/creating-buckets#command-line):

```bash
gcloud storage buckets create gs://${BUCKET_NAME}
```

For the Bucket environment variables, you can either access access keys for your user account or create an access keys for service accounts [here](https://console.cloud.google.com/storage/settings;tab=interoperability).

## Updating manifests

There are a number of manifests that require updating with the environment variable values.
Some of this data is sensitive. For that reason, the files have been added to
`.gitignore`. You should _not_ include these if you push your changes to a remote repository.

To create these secrets use:
```bash
./generate-secrets
```

## Configuring Kratix

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

You can use any of the Promises in the [Kratix Marketplace](https://docs.kratix.io/marketplace) or any custom Promises. We recommend that you can get started with the Cloud SQL promises found [here](https://github.com/syntasso/kratix-marketplace/tree/main/sql/gcp).
