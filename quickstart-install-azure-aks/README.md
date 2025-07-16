# Kratix on Azure Kubernetes Service (AKS)

Welcome to the repository for deploying Kratix on AKS.

These manifests are designed to be used alongside the [video demo](https://www.youtube.com/watch?v=pj_AEaPdJjg)
and related [docs](https://docs.kratix.io/main/guides/installing-kratix-AKS).

These docs assume:
1. You have the `az` CLI installed and are currently logged in
1. You have created a Azure Git Repo you want Kratix to write to

## Setting local variables

Given these manifests require permissions to both your Azure Cloud Platform
(Azure) account, you will need the following environment variables set. Where possible,
sensible defaults have been set:

```bash
export DIR_EXAMPLES=$(pwd)
export AZURE_SERVICE_PRINCIPAL_ID=
export AZURE_SERVICE_PRINCIPAL_KEY_PATH=
export AZURE_TENANT_ID=
export GIT_REPO_URL=
export GIT_REPO_USER=
export GIT_REPO_TOKEN=
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
