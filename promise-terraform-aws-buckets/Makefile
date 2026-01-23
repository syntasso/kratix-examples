IMG_TAG=kratix-workshop/s3-promise-pipeline:v0.1.0

.PHONY: build-pipeline-image
build-pipeline-image: ## Build the Promise Pipeline Docker image
	docker build -t ${IMG_TAG} workflows/promise/configure/dependencies/configure-deps

.PHONY: build-and-load-pipeline-image
build-and-load-pipeline-image: build-pipeline-image ## Builds and loads the pipeline image into the Platform cluster
	kind load docker-image ${IMG_TAG} --name platform
