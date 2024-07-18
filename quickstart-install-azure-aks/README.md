# Kratix on Azure Kubernetes Service (AKS)

Welcome to the repository for deploying Kratix on AKS.

These manifests are designed to be used alongside the [video demo](https://www.youtube.com/watch?v=pj_AEaPdJjg)
and related [docs](https://docs.kratix.io/main/guides/installing-kratix-AKS).

These docs assume:
1. You have the `az` CLI installed and are currently logged in
1. You have created a Azure Git Repo you want Kratix to write to

## Setting local variables

Given these manifests require permissions to both your Azure Cloud Platform
(Azure) account, you will need the following environment variables set:

```
DIR_EXAMPLES
AZURE_SERVICE_PRINCIPAL_ID
AZURE_SERVICE_PRINCIPAL_KEY_PATH
AZURE_TENANT_ID
GIT_REPO_URL
GIT_REPO_USER
GIT_REPO_TOKEN
```

Defaults which may work for you are:

```
export DIR_EXAMPLES=$(pwd)
```

For the `GIT_REPO_URL`, `GIT_REPO_USER` and `GIT_REPO_TOKEN` environment variables, you can create a new Git repo in [Azure
Devops](https://azure.microsoft.com/en-gb/products/devops/?nav=min) and create
a [Personal Access Token to access it](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops)

For the `AZURE_SERVICE_PRINCIPAL_ID`, `AZURE_SERVICE_PRINCIPAL_KEY_PATH` and
`AZURE_TENANT_ID` environment variables, you can create a new service principal
in the [Azure
portal](https://learn.microsoft.com/en-us/cli/azure/azure-cli-sp-tutorial-1?tabs=bash)
and give it permissions to provision SQL instances.

## Updating manifests

There are a number of manifests that require updating with the environment variable values.
Some of this data is sensitive. For that reason, the files have been added to
`.gitignore`. You should _not_ include these if you push your changes to a remote repository.


### Setting gcloud access

```
mkdir -p ${DIR_EXAMPLES}/secrets && rm ${DIR_EXAMPLES}/secrets/**
sed \
    -e s/AZURE_SERVICE_PRINCIPAL_ID/$(echo -n $AZURE_SERVICE_PRINCIPAL_ID | base64)/ \
    -e s/AZURE_SERVICE_PRINCIPAL_KEY/$(cat ${AZURE_SERVICE_PRINCIPAL_KEY_PATH} | base64 )/ \
    -e s/AZURE_TENANT_ID/$(echo $AZURE_TENANT_ID | base64)/ \
    ${DIR_EXAMPLES}/secrets.template/promise-secret.yaml > ${DIR_EXAMPLES}/secrets/promise-secret.yaml

sed \
    -e "s/GIT_REPO_USER/$GIT_REPO_USER/" \
    -e "s/GIT_REPO_TOKEN/$GIT_REPO_TOKEN/" \
    ${DIR_EXAMPLES}/secrets.template/gitrepository-secret.yaml > ${DIR_EXAMPLES}/secrets/gitrepository-secret.yaml

sed \
    -e "s/GIT_REPO_USER/$GIT_REPO_USER/" \
    -e "s/GIT_REPO_TOKEN/$GIT_REPO_TOKEN/" \
    ${DIR_EXAMPLES}/secrets.template/gitstatestore-secret.yaml > ${DIR_EXAMPLES}/secrets/gitstatestore-secret.yaml

sed \
    -e "s^GIT_REPO_URL^$GIT_REPO_URL^" \
    ${DIR_EXAMPLES}/secrets.template/gitrepository.yaml > ${DIR_EXAMPLES}/secrets/gitrepository.yaml

sed \
    -e "s^GIT_REPO_URL^$GIT_REPO_URL^" \
    ${DIR_EXAMPLES}/secrets.template/gitstatestore.yaml > ${DIR_EXAMPLES}/secrets/gitstatestore.yaml
```
