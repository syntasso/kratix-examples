GHCR_ORG=ghcr.io/syntasso/kratix-examples
IMG_TAG=${GHCR_ORG}/kratix-workshop/s3-promise-pipeline:v0.1.0
DEST_IMG_TAG=${GHCR_ORG}/kratix-guide/s3-bucket-dest-resource-pipeline:v0.1.0

.PHONY: build-pipeline-image
build-pipeline-image: ## Build the Promise Pipeline Docker image
	docker build -t ${IMG_TAG} workflows/promise/configure/dependencies/configure-deps --platform linux/amd64

.PHONY: build-and-load-pipeline-image
build-and-load-pipeline-image: build-pipeline-image ## Builds and loads the pipeline image into the Platform cluster
	kind load docker-image ${IMG_TAG} --name platform

.PHONY: build-dest-pipeline
build-dest-pipeline:
	docker build -t ${DEST_IMG_TAG} workflows/resource/configure/s3-bucket-dest-selectors/kratix-guide-s3-bucket-dest-resource-pipeline --platform linux/amd64

.PHONY: build-and-load-dest-pipeline-image
build-and-load-dest-pipeline-image: build-dest-pipeline
	kind load docker-image ${DEST_IMG_TAG} --name platform

build-and-push: build-pipeline-image build-dest-pipeline
	docker push ${IMG_TAG}
	docker push ${DEST_IMG_TAG}
