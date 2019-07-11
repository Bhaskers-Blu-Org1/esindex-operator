
# Image URL to use all building/pushing image targets
IMG ?= cloudoperators/esindex-operator
TAG ?= 0.1.0
GOFILES = $(shell find . -type f -name '*.go' -not -path "./vendor/*")


all: test manager

# Run tests
test: generate fmt vet manifests
	go test ./pkg/... ./cmd/... -coverprofile cover.out

# Build manager binary
manager: generate fmt vet
	go build -o bin/manager github.com/ibm/esindex-operator/cmd/manager

# Run against the configured Kubernetes cluster in ~/.kube/config
run: generate fmt vet
	go run ./cmd/manager/main.go

# Install CRDs into a cluster
install: manifests
	kubectl apply -f config/crds

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
deploy: manifests
	kubectl apply -f config/crds
	kustomize build config/default | kubectl apply -f -

# Generate manifests e.g. CRD, RBAC etc.
manifests:
	go run vendor/sigs.k8s.io/controller-tools/cmd/controller-gen/main.go all

# Run go fmt against code
fmt:
	go fmt ./pkg/... ./cmd/...

# Run go vet against code
vet:
	go vet ./pkg/... ./cmd/...

# Generate code
generate:
	go generate ./pkg/... ./cmd/...

# Build the docker image
docker-build: check-tag
	git rev-parse --short HEAD > git-rev
	docker build . -t ${IMG}:${TAG}
	rm git-rev
	@echo "updating kustomize image patch file for manager resource"
	sed -i'' -e 's@image: .*@image: '"${IMG}:${TAG}"'@' ./config/default/manager_image_patch.yaml

# Push the docker image
docker-push: check-tag
	echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
	docker push ${IMG}:${TAG}
