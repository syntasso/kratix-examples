# Kratix on Google Kubernetes Engine (GKE)

Welcome to the repository for deploying Kratix on GKE.

These manifests are designed to be used alongside the [video demo](https://www.youtube.com/watch?v=Zkh3FIGMsds)
and related [docs](https://docs.kratix.io/main/guides/installing-kratix-GKE).

These docs assume:
1. You have the `gcloud` CLI installed and are currently logged in
1. You have created a GCP bucket you want Kratix to write to

## Setting local variables

Given these manifests require permissions to both your Google Cloud Platform
(GCP) account, you will need the following environment variables set. Where possible,
sensible defaults have been set:

```bash
export DIR_EXAMPLES=$(pwd)
export BUCKET_NAME="kratix-$(whoami)-${RANDOM}"
export BUCKET_ACCESS_KEY=
export BUCKET_SECRET_KEY=
```

For the Bucket environment variables, you can create a new bucket in the GCP and
then create a key [here](https://console.cloud.google.com/storage/settings).

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

You can use any of the Promises in the [Kratix Marketplace](https://docs.kratix.io/marketplace) or any custom Promises. We recommend that you can get started with the Cloud SQL promises found [here](https://github.com/syntasso/kratix-marketplace/tree/main/sql).
