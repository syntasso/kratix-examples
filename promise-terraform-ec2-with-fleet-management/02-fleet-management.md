# Fleet Management with Kratix Promises

Welcome to Part 2 of the tutorial!

If you haven’t completed Part 1 yet, head over to
[01-terraform-promise/README.md](../01-terraform-promise/README.md) to learn how
to build a Terraform-based Promise and deploy EC2 instances via a self-serve
Kratix API. It’s a great intro to the power of Promises and a solid foundation
for what we’re about to explore.

## Recap

In Part 1, we:

- Bootstrapped a Kratix Promise using a public Terraform module

- Enabled platform users to create and destroy platform approved EC2 instances
via a simple API

Pretty cool, right? But that’s just the beginning.

## The Real Power of Promises: Fleet Management

While self-service is a huge win on its own, Kratix really shines when you use
it to manage infrastructure **as a fleet**.

Why? Because once your users are making requests via a Promise, all of their
infrastructure is defined declaratively and managed by Kratix. Which means…

> 💡 **If you want to roll out a change to every single request, you just update
> the Promise.**

No need to chase down individual repos or pipelines. No scripts or mass PRs.
Just change the Promise spec, apply it, and watch Kratix upgrade the entire
fleet for you. Effortless governance and evolution at scale.

Let’s see that in action.

---

## Step 1: Make a Few More Requests

Start by creating a few more VM resources using the same Promise. You can copy
and tweak the `example-request.yaml` from Part 1.

```yaml 
# example-request-1.yaml 
apiVersion: example.com/v1
kind: VM
metadata:
  name: vm-1
spec:
  subnet_id: subnet-123456789abcdefg
```

```yaml 
# example-request-2.yaml 
apiVersion: example.com/v1
kind: VM
metadata:
  name: vm-2
spec:
  subnet_id: subnet-123456789abcdefg
```

```yaml 
# example-request-3.yaml 
apiVersion: example.com/v1
kind: VM
metadata:
  name: vm-3 
spec:
  subnet_id: subnet-123456789abcdefg
```

Apply all three:

```bash 
kubectl apply -f example-request-1.yaml -f example-request-2.yaml -f example-request-3.yaml
```

These will each go through the Promise’s workflows and provision EC2 instances
in AWS.

## Step 2: Make a Change to the Promise

Now let’s simulate a real-world update: The platform team decide to mandate that all VMs provisioned need to follow a strict tagging protocol. In the world where app devs are managing their own terraform, the platform team has to ask each engineer to update their terraform and the turnaround will be paifully slow. With Kratix, all we have to do is update the Promise workflow to have a container
modify the terraform before it reaches the apply step.

Add the following container **between the `terraform-plan` and `terraform-apply` steps** in your `promise.yaml`:

```yaml
            - name: enforce-tags
              image: ghcr.io/syntasso/kratix-pipeline-utility:v0.0.1
              command:
                - /bin/sh
                - -c
                - |
                  set -euo pipefail

                  echo "Reading inputs from /kratix/input/object.yaml"
                  NAME=$(awk '/^[[:space:]]*name:/ { print $2; exit }' /kratix/input/object.yaml | tr -d '"')
                  NAMESPACE=$(awk '/^[[:space:]]*namespace:/ { print $2; exit }' /kratix/input/object.yaml | tr -d '"')

                  # this is the naming convention for the Terraform file that the `terraform-generate` step will create
                  # the KRATIX_PROMISE_NAME is set for us by Kratix, and in this case resolves to "vm"
                  UNIQUE_NAME=${KRATIX_PROMISE_NAME}_${NAMESPACE}_${NAME}
                  TF_FILE="/kratix/output/${UNIQUE_NAME}.tf.json"

                  echo "📝 Adding default tags to $TF_FILE"
                  jq ".module[\"${UNIQUE_NAME}\"].tags = {
                    \"managed-by\": \"kratix\",
                    \"kratix.io/promise\": \"vm\",
                    \"kratix.io/request-namespace\": \"${NAMESPACE}\",
                    \"kratix.io/request-name\": \"${NAME}\"
                  }" "$TF_FILE" > tmp.json && mv tmp.json "$TF_FILE"

```

<details>
  <summary>Click here to see what the full `promise.yaml` should look like so far</summary>
  TODO
</details>


## Step 3: Watch the Fleet Update

When we apply the updated Promise, Kratix will:
- Re-run the workflows for all existing resource requests
  - this will re-generate the Terraform files for each request, including the
  new tags
- Apply your change to every instance

Apply the updated Promise:

```bash
kubectl apply -f promise.yaml
```

You can track the updates by watching the workload Pods:

```bash
kubectl get pods -l kratix.io/promise-name=vm -w
```

If you check the EC2 instances in your AWS account, you should now see all of
them tagged with `managed-by=kratix` and `environment=dev`.

No manual updates. No user intervention. Just one Promise change = instant
fleet-wide upgrade.

## Summary

With just a few YAML edits, you’ve now seen how Kratix enables rapid rollout of
changes across all infrastructure created via a Promise. This kind of control is
what makes Kratix a powerful platform building tool—not just for self-service,
but for managing infrastructure at scale.
