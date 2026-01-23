# Terraform AWS Buckets Promise

This Promise is an example that shows how to drive the creation of Terraform
resources using Kratix. For this particular use case, we focus on creating S3
buckets in AWS.

It was created using the instructions from [this
guide](https://docs.kratix.io/ske/guides/promise-from-tf-module).

## API properties

The properties exposed by this API come from the [Terraform module for S3
Buckets at version
1.51.0](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v5.10.0).

To add changes to this Promise's API, you can use the `kratix update api`
command, for example:
```
kratix update api --property name:string --property team --kind S3
```

## Updating Workflows

To add workflow containers, you can use the `kratix add container` command:

```
kratix add container resource/configure/pipeline0 --image syntasso/postgres-resource:v1.0.0
```

## Updating Dependencies

TBD
