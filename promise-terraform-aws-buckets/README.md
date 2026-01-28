# Terraform AWS Buckets Promise

This Promise is an example that shows how to drive the creation of Terraform
resources using Kratix. For this particular use case, we focus on creating S3
buckets in AWS.

It was created using the instructions from [this
guide](https://docs.kratix.io/ske/guides/promise-from-tf-module).

## API properties

To add changes to this Promise's API, you can use the `kratix update api`
command, for example:
```
kratix update api --property team:string
```

## Updating Workflows

To add workflow containers, you can use the `kratix add container` command:

```
kratix add container resource/configure/s3-bucket-dest --image kratix-guide/s3-bucket-dest-resource-pipeline:v0.1.0 --language python
```

## Updating Dependencies

TBD
