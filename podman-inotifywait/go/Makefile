# Demo of using podman on Windows, Mac, or Linux

# Turn off default Make rules
.SUFFIXES:

#### Variables

# golang version
GO_VERSION := "latest"

# golang docker image ref
IMAGE_REF := "golang:1.23rc1-alpine3.20"

#### Targets

# Default target
.PHONY: all
all: pull clean build run

# Pull docker image
.PHONY: pull
.SILENT: pull
pull:
	[ `podman image list --format "{{.ID}}" --filter "reference=$(IMAGE_REF)" | wc -l` -eq 1 ] || podman pull $(IMAGE_REF)

# Build docker image
build: app/main.go Containerfile
	podman build --build-arg "IMAGE_REF=$(IMAGE_REF)" -t hello:1.0 .
	@touch build

# Run docker image
.PHONY: run
run:
	podman run --name=hello -v $$(pwd)/app:/app hello:1.0

# Clean artifacts: delete generated files, remove all containers related to the image, and the image itself
# The only thing not removed is the golang container needed to build the code
.PHONY: clean
.SILENT: clean
clean:
	rm -f hello.go Dockerfile build
	for id in `podman ps -a --format "{{.ID}} {{.Image}}" | grep hello:1.0 | awk '{print $$1}'`; do \
		echo "Removing container $$id"; \
		podman rm "$$id"; \
	done
	for id in `podman image ls --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep hello:1.0 | awk '{print $$1}'`; do \
		echo "Removing image $$id"; \
		podman image rm "$$id"; \
	done
