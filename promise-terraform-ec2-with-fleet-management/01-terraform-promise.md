# Terraform Promise

In this README, we’ll explain how to create and customise a Kratix Promise by
bootstrapping it from a Terraform module.

## Prerequisites

To complete this tutorial, you’ll need access to:

- A Kubernetes Cluster: Any provider can be used.
  - **Kratix installed**. Check out the [quick start
  guide](https://docs.kratix.io/main/quick-start) for instructions on how to set
  up Kratix in your cluster.

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

  ```yaml
  apiVersion: platform.kratix.io/v1alpha1
  kind: Promise
  metadata:
    name: vm
    labels:
      kratix.io/promise-version: v0.0.1
  spec:
    api:
      apiVersion: apiextensions.k8s.io/v1
      kind: CustomResourceDefinition
      metadata:
        name: vms.example.com
      spec:
        group: example.com
        names:
          kind: VM
          plural: vms
          singular: vm
        scope: Namespaced
        versions:
          - name: v1
            schema:
              openAPIV3Schema:
                type: object
                properties:
                  spec:
                    properties:
                      ami:
                        description: ID of AMI to use for the instance
                        type: string
                      ami_ssm_parameter:
                        default: /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
                        description: SSM parameter name for the AMI ID. For Amazon Linux AMI SSM parameters
                          see [reference](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-public-parameters-ami.html)
                        type: string
                      associate_public_ip_address:
                        description: Whether to associate a public IP address with an instance in a VPC
                        type: boolean
                      availability_zone:
                        description: AZ to start the instance in
                        type: string
                      capacity_reservation_specification:
                        description: Describes an instance's Capacity Reservation targeting option
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      cpu_credits:
                        description: The credit option for CPU usage (unlimited or standard)
                        type: string
                      cpu_options:
                        description: Defines CPU options to apply to the instance at launch time.
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      create:
                        default: true
                        description: Whether to create an instance
                        type: boolean
                      create_eip:
                        default: false
                        description: Determines whether a public EIP will be created and associated with
                          the instance.
                        type: boolean
                      create_iam_instance_profile:
                        default: false
                        description: Determines whether an IAM instance profile is created or to use an
                          existing IAM instance profile
                        type: boolean
                      create_security_group:
                        default: true
                        description: Determines whether a security group will be created
                        type: boolean
                      create_spot_instance:
                        default: false
                        description: Depicts if the instance is a spot instance
                        type: boolean
                      disable_api_stop:
                        description: If true, enables EC2 Instance Stop Protection
                        type: boolean
                      disable_api_termination:
                        description: If true, enables EC2 Instance Termination Protection
                        type: boolean
                      ebs_optimized:
                        description: If true, the launched EC2 instance will be EBS-optimized
                        type: boolean
                      ebs_volumes:
                        additionalProperties:
                          type: object
                          x-kubernetes-preserve-unknown-fields: true
                        description: Additional EBS volumes to attach to the instance
                        type: object
                      eip_domain:
                        default: vpc
                        description: Indicates if this EIP is for use in VPC
                        type: string
                      eip_tags:
                        additionalProperties:
                          type: string
                        default: {}
                        description: A map of additional tags to add to the eip
                        type: object
                      enable_primary_ipv6:
                        description: Whether to assign a primary IPv6 Global Unicast Address (GUA) to
                          the instance when launched in a dual-stack or IPv6-only subnet
                        type: boolean
                      enable_volume_tags:
                        default: true
                        description: Whether to enable volume tags (if enabled it conflicts with root_block_device
                          tags)
                        type: boolean
                      enclave_options_enabled:
                        description: Whether Nitro Enclaves will be enabled on the instance. Defaults
                          to `false`
                        type: boolean
                      ephemeral_block_device:
                        additionalProperties:
                          type: object
                          x-kubernetes-preserve-unknown-fields: true
                        description: Customize Ephemeral (also known as Instance Store) volumes on the
                          instance
                        type: object
                      get_password_data:
                        description: If true, wait for password data to become available and retrieve
                          it
                        type: boolean
                      hibernation:
                        description: If true, the launched EC2 instance will support hibernation
                        type: boolean
                      host_id:
                        description: ID of a dedicated host that the instance will be assigned to. Use
                          when an instance is to be launched on a specific dedicated host
                        type: string
                      host_resource_group_arn:
                        description: ARN of the host resource group in which to launch the instances.
                          If you specify an ARN, omit the `tenancy` parameter or set it to `host`
                        type: string
                      iam_instance_profile:
                        description: IAM Instance Profile to launch the instance with. Specified as the
                          name of the Instance Profile
                        type: string
                      iam_role_description:
                        description: Description of the role
                        type: string
                      iam_role_name:
                        description: Name to use on IAM role created
                        type: string
                      iam_role_path:
                        description: IAM role path
                        type: string
                      iam_role_permissions_boundary:
                        description: ARN of the policy that is used to set the permissions boundary for
                          the IAM role
                        type: string
                      iam_role_policies:
                        additionalProperties:
                          type: string
                        default: {}
                        description: Policies attached to the IAM role
                        type: object
                      iam_role_tags:
                        additionalProperties:
                          type: string
                        default: {}
                        description: A map of additional tags to add to the IAM role/profile created
                        type: object
                      iam_role_use_name_prefix:
                        default: true
                        description: Determines whether the IAM role name (`iam_role_name` or `name`)
                          is used as a prefix
                        type: boolean
                      ignore_ami_changes:
                        default: false
                        description: Whether changes to the AMI ID changes should be ignored by Terraform.
                          Note - changing this value will result in the replacement of the instance
                        type: boolean
                      instance_initiated_shutdown_behavior:
                        description: Shutdown behavior for the instance. Amazon defaults this to stop
                          for EBS-backed instances and terminate for instance-store instances. Cannot
                          be set on instance-store instance
                        type: string
                      instance_market_options:
                        description: The market (purchasing) option for the instance. If set, overrides
                          the `create_spot_instance` variable
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      instance_tags:
                        additionalProperties:
                          type: string
                        default: {}
                        description: Additional tags for the instance
                        type: object
                      instance_type:
                        default: t3.micro
                        description: The type of instance to start
                        type: string
                      ipv6_address_count:
                        description: A number of IPv6 addresses to associate with the primary network
                          interface. Amazon EC2 chooses the IPv6 addresses from the range of your subnet
                        type: number
                      ipv6_addresses:
                        description: Specify one or more IPv6 addresses from the range of the subnet to
                          associate with the primary network interface
                        items:
                          type: string
                        type: array
                      key_name:
                        description: Key name of the Key Pair to use for the instance; which can be managed
                          using the `aws_key_pair` resource
                        type: string
                      launch_template:
                        description: Specifies a Launch Template to configure the instance. Parameters
                          configured on this resource will override the corresponding parameters in the
                          Launch Template
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      maintenance_options:
                        description: The maintenance options for the instance
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      metadata_options:
                        description: Customize the metadata options of the instance
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      monitoring:
                        description: If true, the launched EC2 instance will have detailed monitoring
                          enabled
                        type: boolean
                      name:
                        default: ""
                        description: Name to be used on EC2 instance created
                        type: string
                      network_interface:
                        additionalProperties:
                          type: object
                          x-kubernetes-preserve-unknown-fields: true
                        description: Customize network interfaces to be attached at instance boot time
                        type: object
                      placement_group:
                        description: The Placement Group to start the instance in
                        type: string
                      placement_partition_number:
                        description: Number of the partition the instance is in. Valid only if the `aws_placement_group`
                          resource's `strategy` argument is set to `partition`
                        type: number
                      private_dns_name_options:
                        description: Customize the private DNS name options of the instance
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      private_ip:
                        description: Private IP address to associate with the instance in a VPC
                        type: string
                      putin_khuylo:
                        default: true
                        description: 'Do you agree that Putin doesn''t respect Ukrainian sovereignty and
                          territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo!'
                        type: boolean
                      region:
                        description: Region where the resource(s) will be managed. Defaults to the Region
                          set in the provider configuration
                        type: string
                      root_block_device:
                        description: Customize details about the root block device of the instance. See
                          Block Devices below for details
                        type: object
                        x-kubernetes-preserve-unknown-fields: true
                      secondary_private_ips:
                        description: A list of secondary private IPv4 addresses to assign to the instance's
                          primary network interface (eth0) in a VPC. Can only be assigned to the primary
                          network interface (eth0) attached at instance creation, not a pre-existing network
                          interface i.e. referenced in a `network_interface block`
                        items:
                          type: string
                        type: array
                      security_group_description:
                        description: Description of the security group
                        type: string
                      security_group_egress_rules:
                        additionalProperties:
                          type: object
                          x-kubernetes-preserve-unknown-fields: true
                        description: Egress rules to add to the security group
                        type: object
                      security_group_ingress_rules:
                        additionalProperties:
                          type: object
                          x-kubernetes-preserve-unknown-fields: true
                        description: Egress rules to add to the security group
                        type: object
                      security_group_name:
                        description: Name to use on security group created
                        type: string
                      security_group_tags:
                        additionalProperties:
                          type: string
                        default: {}
                        description: A map of additional tags to add to the security group created
                        type: object
                      security_group_use_name_prefix:
                        default: true
                        description: Determines whether the security group name (`security_group_name`
                          or `name`) is used as a prefix
                        type: boolean
                      security_group_vpc_id:
                        description: VPC ID to create the security group in. If not set, the security
                          group will be created in the default VPC
                        type: string
                      source_dest_check:
                        description: Controls if traffic is routed to the instance when the destination
                          address does not match the instance. Used for NAT or VPNs
                        type: boolean
                      spot_instance_interruption_behavior:
                        description: Indicates Spot instance behavior when it is interrupted. Valid values
                          are `terminate`, `stop`, or `hibernate`
                        type: string
                      spot_launch_group:
                        description: A launch group is a group of spot instances that launch together
                          and terminate together. If left empty instances are launched and terminated
                          individually
                        type: string
                      spot_price:
                        description: The maximum price to request on the spot market. Defaults to on-demand
                          price
                        type: string
                      spot_type:
                        description: If set to one-time, after the instance is terminated, the spot request
                          will be closed. Default `persistent`
                        type: string
                      spot_valid_from:
                        description: The start date and time of the request, in UTC RFC3339 format(for
                          example, YYYY-MM-DDTHH:MM:SSZ)
                        type: string
                      spot_valid_until:
                        description: The end date and time of the request, in UTC RFC3339 format(for example,
                          YYYY-MM-DDTHH:MM:SSZ)
                        type: string
                      spot_wait_for_fulfillment:
                        description: If set, Terraform will wait for the Spot Request to be fulfilled,
                          and will throw an error if the timeout of 10m is reached
                        type: boolean
                      subnet_id:
                        description: The VPC Subnet ID to launch in
                        type: string
                      tags:
                        additionalProperties:
                          type: string
                        default: {}
                        description: A mapping of tags to assign to the resource
                        type: object
                      tenancy:
                        description: 'The tenancy of the instance (if the instance is running in a VPC).
                          Available values: default, dedicated, host'
                        type: string
                      timeouts:
                        additionalProperties:
                          type: string
                        default: {}
                        description: Define maximum timeout for creating, updating, and deleting EC2 instance
                          resources
                        type: object
                      user_data:
                        description: The user data to provide when launching the instance. Do not pass
                          gzip-compressed data via this argument; see user_data_base64 instead
                        type: string
                      user_data_base64:
                        description: Can be used instead of user_data to pass base64-encoded binary data
                          directly. Use this instead of user_data whenever the value is not a valid UTF-8
                          string. For example, gzip-encoded user data must be base64-encoded and passed
                          via this argument to avoid corruption
                        type: string
                      user_data_replace_on_change:
                        description: When used in combination with user_data or user_data_base64 will
                          trigger a destroy and recreate when set to true. Defaults to false if not set
                        type: boolean
                      volume_tags:
                        additionalProperties:
                          type: string
                        default: {}
                        description: A mapping of tags to assign to the devices created by the instance
                          at launch time
                        type: object
                      vpc_security_group_ids:
                        default: null
                        description: A list of security group IDs to associate with
                        items:
                          type: string
                        type: array
                    type: object
            served: true
            storage: true
    destinationSelectors:
      - matchLabels:
          environment: terraform
    workflows:
      promise:
        configure:
          []
      resource:
        configure:
          - apiVersion: platform.kratix.io/v1alpha1
            kind: Pipeline
            metadata:
              name: instance-configure
            spec:
              containers:
              - env:
                - name: MODULE_SOURCE
                  value: https://github.com/terraform-aws-modules/terraform-aws-ec2-instance
                - name: MODULE_VERSION
                  value: v6.0.2
                image: ghcr.io/syntasso/kratix-cli/terraform-generate:v0.1.0
                name: terraform-generate
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

Next ⏭️ [02-fleet-management.md](./02-fleet-management.md)
