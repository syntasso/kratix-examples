# Kratix on Google Kubernetes Engine (GKE)

Welcome to the repository for deploying Kratix on GKE.

These manifests are designed to be used alongside the [video demo](tbd)
and related [docs](https://docs.kratix.io/main/guides/installing-kratix-GKE).

These docs assume:
1. You have the `gcloud` CLI installed and are currently logged in
1. You have created a GCP bucket you want Kratix to write to

## Setting local variables

Given these manifests require permissions to both your Google Cloud Platform
(GCP) account, you will need the following environment variables set:

```
DIR_GCLOUD_CONFIG
DIR_EXAMPLES
BUCKET_NAME
BUCKET_ACCESS_KEY
BUCKET_SECRET_KEY
```

Defaults which may work for you are:
```
export DIR_GCLOUD_CONFIG="${HOME}/.config/gcloud"
export DIR_EXAMPLES=$(pwd)
export BUCKET_NAME="kratix-$(whoami)-${RANDOM}"
```

For the Bucket environment variables, you can create a new bucket in the GCP and
then create a key [here](https://console.cloud.google.com/storage/settings).

## Updating manifests

There are a number of manifests that require updating with the environment variable values.
Some of this data is sensitive. For that reason, the files have been added to
`.gitignore`. You should _not_ include these if you push your changes to a remote repository.


### Setting gcloud access

```
mkdir -p ${DIR_EXAMPLES}/secrets && rm ${DIR_EXAMPLES}/secrets/**
sed \
    -e s/BASE64_ACTIVE_PROJECT_ID/$(sed -n -e 's/^project = //p' ${DIR_GCLOUD_CONFIG}/configurations/config_$(cat ${DIR_GCLOUD_CONFIG}/active_config) | base64 -w0)/ \
    -e s/BASE64_CREDS/$(cat ${DIR_GCLOUD_CONFIG}/application_default_credentials.json | base64 -w0)/ \
    ${DIR_EXAMPLES}/secrets.template/promise-secret.yaml > ${DIR_EXAMPLES}/secrets/promise-secret.yaml

sed \
    -e "s@BUCKET_ACCESS_KEY@$(echo -n ${BUCKET_ACCESS_KEY}|base64 -w0)@" \
    -e "s@BUCKET_SECRET_KEY@$(echo -n ${BUCKET_SECRET_KEY}|base64 -w0)@" \
    ${DIR_EXAMPLES}/secrets.template/bucket-secret.yaml > ${DIR_EXAMPLES}/secrets/bucket-secret.yaml

sed \
    -e "s@BUCKET_ACCESS_KEY@$(echo -n ${BUCKET_ACCESS_KEY}|base64 -w0)@" \
    -e "s@BUCKET_SECRET_KEY@$(echo -n ${BUCKET_SECRET_KEY}|base64 -w0)@" \
    ${DIR_EXAMPLES}/secrets.template/bucketstatestore-secret.yaml > ${DIR_EXAMPLES}/secrets/bucketstatestore-secret.yaml

sed \
    -e "s@BUCKET_NAME@${BUCKET_NAME}@" \
    ${DIR_EXAMPLES}/secrets.template/bucket.yaml > ${DIR_EXAMPLES}/secrets/bucket.yaml

sed \
    -e "s@BUCKET_NAME@${BUCKET_NAME}@" \
    ${DIR_EXAMPLES}/secrets.template/bucketstatestore.yaml > ${DIR_EXAMPLES}/secrets/bucketstatestore.yaml
```
