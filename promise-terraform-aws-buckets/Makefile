IMG_TAG=kratix-workshop/s3-promise-pipeline:v0.1.0

.PHONY: build-pipeline-image
build-pipeline-image: ## Build the Promise Pipeline Docker image
	docker build -t ${IMG_TAG} workflows/promise/configure/dependencies/configure-deps

.PHONY: build-and-load-pipeline-image
build-and-load-pipeline-image: build-pipeline-image ## Builds and loads the pipeline image into the Platform cluster
	kind load docker-image ${IMG_TAG} --name platform

DEST_IMG_TAG=kratix-guide/s3-bucket-dest-resource-pipeline:v0.1.0

.PHONY: build-dest-pipeline
build-dest-pipeline:
	docker build -t ${DEST_IMG_TAG} workflows/resource/configure/s3-bucket-dest-selectors/kratix-guide-s3-bucket-dest-resource-pipeline

.PHONY: build-and-load-dest-pipeline-image
build-and-load-dest-pipeline-image: build-dest-pipeline
	kind load docker-image ${DEST_IMG_TAG} --name platform