# Terraform Promise

In this README, we’ll explain how to create and customise a Kratix Promise by
bootstrapping it from a Terraform module.

## Prerequisites

To complete this tutorial, you’ll need access to:

- A Kubernetes Cluster: Any provider can be used.

- An AWS (or other cloud provider) account: Required for provisioning Terraform
resources.

- The following CLIs:

  - **kubectl**: For interacting with the Kubernetes cluster
  
  - [**kratix**](https://github.com/syntasso/kratix-cli/releases): For
  bootstrapping the Promise

## Introduction

Terraform is a popular Infrastructure as Code (IaC) tool that lets you define
and provision infrastructure using declarative configuration files. In many
platform setups, Terraform is used to manage infrastructure in one of two ways:

- Centrally managed by a platform team
  - Developers raise tickets or PRs to request infrastructure changes
- Directly managed by developers
  - Developers write, run, and maintain their own Terraform code

Both approaches come with challenges, such as:

- Centralised workflows can lead to provisioning bottlenecks and delays
- Developer-managed Terraform can result in inconsistencies, duplication, and
  governance gaps, along with high cognitive overhead

Kratix helps address these challenges by making it easy to expose infrastructure
as a self-service API. Once consumed via Kratix, resources can be managed as a
fleet, enabling governance, consistency, and low overhead, all while offering a
great user experience.

In this example, we’ll demonstrate how to create a self-serve, fleet-managed
infrastructure offering using Kratix. We'll use the
[terraform-aws-ec2-instance](https://github.com/terraform-aws-modules/terraform-aws-ec2-instance)
module as an example, but you can substitute in any Terraform module you like.

## Promise

A [Promise](https://docs.kratix.io/main/reference/promises/intro) in Kratix is composed of four components:

- API: Defines the input schema for user requests

- Workflows: A series of Docker containers that run when a user creates, updates,
  deletes a request, or at intervals for drift detection

- Dependencies: External dependencies that must be resolved before accepting requests

- Destination Selectors: Define where the Promise will schedule workloads

In this tutorial, we’ll create a Promise that focuses only on the API and Workflow components.
For an example that includes Dependencies and Destination Selectors, refer to the full
[workshop](https://docs.kratix.io/workshop/intro).

### Initialise the Promise

The Kratix CLI provides an `init` command to quickly create a Promise from a
Terraform module. This command creates:

- An API that mirrors the variables defined in the Terraform module
- A Workflow that reads those API inputs and generates Terraform code to create
  the resources

This is a strong starting point and can be customised as needed.

To initialise the Promise, run the following command in the directory where you
want to generate the Promise, update the `--dir` flag to point to your desired
directory to store the Promise in, or or keep as `.` to use the current directory:

```bash
kratix init tf-module-promise vm \
  --group example.com \
  --kind VM \
  --version v1 \
  --dir . \
  --module-version v6.0.2 \
  --module-source https://github.com/terraform-aws-modules/terraform-aws-ec2-instance
```

You may see some **warnings** about defaults not being inferred for all API
fields. This is expected, Kratix doesn’t yet fully support the advanced
defaulting that some Terraform modules offer. Your API will still work; it just
won’t automatically expose all module defaults.

After running the command, inspect the generated `promise.yaml`. You’ll find:

- An API generated from the module’s variables, with some defaults set
- A Workflow that runs a single container to generate Terraform code from the user input

This is a great base for your Promise. If you're using GitOps to reconcile
Terraform, you could now simply add a Destination Selector and Kratix would
schedule the generated Terraform to your Git repository.

For simplicity, in this demo we’ll instead run `terraform apply` directly inside
the workflow container.

### Terraform Apply

Let’s update the Promise to run `terraform apply` inside the workflow container.

Add the following container below the existing `terraform-generate` container in
the `promise.yaml` file:

```yaml
            - name: terraform-apply
              image: hashicorp/terraform:1.8.3
              envFrom:
                - secretRef:
                    name: aws-creds
              command:
                - /bin/sh
                - -c
                - |
                  set -euo pipefail
                  echo "Reading inputs from /kratix/input/object.yaml"
                  NAME=$(awk '/^[[:space:]]*name:/ { print $2; exit }' /kratix/input/object.yaml | tr -d '"')
                  NAMESPACE=$(awk '/^[[:space:]]*namespace:/ { print $2; exit }' /kratix/input/object.yaml | tr -d '"')

                  echo "Setting up Terraform working directory"
                  mkdir -p /tmp/tf-apply/
                  cd /tmp/tf-apply/

                  echo "Copying Terraform files from /kratix/output/"
                  cp -r /kratix/output/* .

                  echo "Creating backend.tf file for Terraform state management"
                  cat <<EOF > backend.tf
                  terraform {
                    backend "s3" {
                      bucket = "${BUCKET_NAME}"
                      key    = "envs/${NAMESPACE}-${NAME}-terraform.tfstate"
                      region = "${AWS_REGION}"
                    }
                  }
                  EOF

                  echo "Initialising Terraform"
                  terraform init
                  echo "Applying Terraform configuration"
                  terraform apply -auto-approve
```

Be sure to:

- Indent the container properly so it aligns with `terraform-generate`
- Adjust the credentials/environment variables if you're targeting a cloud
  provider other than AWS

<details>
  <summary>Click here to see what the full `promise.yaml` should look like so far</summary>
  TODO
</details>

Then apply your updated Promise:

```bash
kubectl apply -f promise.yaml
```

Lastly, make sure the `aws-creds` secret exists, include within it the
`BUCKET_NAME` you want to use for storing the Terraform state:

```bash
kubectl create secret generic aws-creds \
  --from-literal=AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  --from-literal=AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  --from-literal=AWS_REGION=$AWS_REGION \
  --from-literal=BUCKET_NAME=<YOUR_S3_BUCKET_NAME_FOR_STORING_TF_STATE>
```

### Testing the Promise

With the Promise created and the secret in place, you can test it by submitting
a request. The `kratix init` command will have created a sample
`example-request.yaml`. Edit it to include a valid `subnet_id`, such as:

```yaml
apiVersion: example.com/v1
kind: VM
metadata:
  name: example-vm
spec:
  subnet_id: subnet-123456789abcdefghi
```

Then apply it:

```bash
kubectl apply -f example-request.yaml
```

This will trigger a workload Pod that runs both the `terraform-generate` and
`terraform-apply` containers. Monitor it with:

```bash
kubectl get pods -l kratix.io/promise-name=vm -w
```

Once the `terraform-generate` container finishes, you can watch the logs for
`terraform-apply`:

```bash
kubectl logs -l kratix.io/promise-name=vm -c terraform-apply -f
```

Once complete, the EC2 instance should be visible in your AWS account.

You’ve now successfully:

- ✅ Created a Promise from a Terraform module
- ✅ Customised it to run `terraform apply` as part of the Workflow
- ✅ Tested it by creating an EC2 instance via a self-serve Kratix API

This provides a solid foundation for building a self-service platform API for
infrastructure. You can now iterate: enhance the API, add policies or
approvals, and more. Let's now add deletion support.

### Enhancing for Deletion

To enable support for deletion, you need to define a `delete` Workflow that runs
when a user deletes their request. This Workflow will run `terraform destroy`.

Add the following block next to the existing `.spec.workflows.resource.configure`
workflow in `promise.yaml`:

```yaml
      delete:
        - apiVersion: platform.kratix.io/v1alpha1
          kind: Pipeline
          metadata:
            name: instance-delete
          spec:
            containers:
            - name: terraform-destroy
              image: hashicorp/terraform:1.8.3
              envFrom:
                - secretRef:
                    name: aws-creds
              command:
                - /bin/sh
                - -c
                - |
                  set -euo pipefail
                  mkdir /tmp/tf-delete/
                  cd /tmp/tf-delete/

                  NAME=$(awk '/^[[:space:]]*name:/ { print $2; exit }' /kratix/input/object.yaml | tr -d '"')
                  NAMESPACE=$(awk '/^[[:space:]]*namespace:/ { print $2; exit }' /kratix/input/object.yaml | tr -d '"')

                  cat <<EOF > backend.tf
                  terraform {
                    backend "s3" {
                      bucket = "${BUCKET_NAME}"
                      key    = "envs/${NAMESPACE}-${NAME}-terraform.tfstate"
                      region = "${AWS_REGION}"
                    }
                  }
                  EOF

                  terraform init
                  terraform destroy -auto-approve
```


<details>
  <summary>Click here to see what the full `promise.yaml` should look like so far</summary>
  TODO
</details>

Apply your updated Promise:

```bash
kubectl apply -f promise.yaml
```

Then test deletion by removing your request:

```bash
kubectl delete -f example-request.yaml
```

This triggers the `instance-delete` workflow and runs the `terraform-destroy`
container to tear down the provisioned infrastructure.

The delete pod runs, and if successfull the resource is deleted from Kratix,
removing all associated Kratix resources (including the delete workflow pod
itself!). If your quick you may see the delete pod in the list of pods while its
deleting the resource:

```bash
kubectl get pods -l kratix.io/promise-name=vm -w
```

You should see the EC2 instance has been destroyed from your AWS account.

### Conclusion
You’ve now created a fully functional Kratix Promise that allows users to:
- ✅ Create an EC2 instance via a self-service API
- ✅ Delete it using the same API

This example demonstrates how Kratix can simplify infrastructure management by
exposing Terraform modules as self-service APIs. You can extend this further by
adding more features, such as:
- Additional API fields for more or less configuration options
- Policies for governance and compliance
- Approvals for sensitive operations
- Integration with other systems for notifications or logging

In the next section, we will show how you can use a Promise to manage its
requests as a fleet, allowing you to apply policies and manage resources at
scale.

[../02-fleet-management/README.md](../02-fleet-management/README.md)
