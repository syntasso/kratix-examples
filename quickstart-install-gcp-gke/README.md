# Kratix on Google Kubernetes Engine (GKE)

Kratix runs on all Kubernetes services including Google Kubernetes Engine (GKE). There are three key components to a Kratix installation:
1. Kratix platform orchestrator
1. A Git or S3 storage backend for declarative code
1. Infrastructure provider to make resources

While all three components are key to the success of a scalable enterprise platform orchestrator, Kratix maintains loose coupling allowing each to be hosted in the same or different providers including air-gapped on-premise environments.

This repository provides scripts to set up an S3 storage backend in Google Cloud. These scripts are not intended for production without personal review. Should you want to discuss production grade deployments, reach out to the creators of Kratix, [Syntasso](https://syntasso.io/).

# Prerequisites

Before continuing please confirm the following pre-requisites:
1. You already have a Kratix installed.
    _(To install Kratix in GKE follow these [docs](https://docs.kratix.io/main/guides/installing-kratix-GKE) or this [video demo](https://www.youtube.com/watch?v=Zkh3FIGMsds))_
1. You have the `gcloud` CLI installed and are currently logged in
1. You have created a GCP bucket you want Kratix to write to _(instructions to create a bucket are included below if needed)_


## Setting local variables

Given these manifests require permissions to both your Google Cloud Platform
(GCP) account, you will need the following environment variables set. Where possible,
sensible defaults have been set:

```bash
export DIR_EXAMPLES=$(pwd)
export BUCKET_NAME="kratix-$(whoami)-${RANDOM}"
```

If you need to create a bucket, you can use the following commands or refer to the [GCP documentation](https://cloud.google.com/storage/docs/creating-buckets#command-line):

```bash
gcloud storage buckets create gs://${BUCKET_NAME}
```

For the Bucket environment variables, you can either access access keys for your user account or create an access keys for service accounts [here](https://console.cloud.google.com/storage/settings;tab=interoperability).

```bash
export BUCKET_ACCESS_KEY=
export BUCKET_SECRET_KEY=
```

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
