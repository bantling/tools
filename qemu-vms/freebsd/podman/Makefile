# // SPDX-License-Identifier: Apache-2.0

# Build a native freebsd postgres container image

# Path to podman, if we have it
PODMAN_PATH := $(shell which podman 2> /dev/null || :)

# The podman base image name
PODMAN_BASE_IMAGE_NAME := $(shell grep FROM Dockerfile.pg | awk '{print $$2}' || :)

# The podman container tag
PODMAN_CONTAINER_TAG := localhost/pg

# The podman container name
PODMAN_CONTAINER_NAME := pg

# The postgres user name
POSTGRES_USER := pguser

# The postgres user password
POSTGRES_PASSWORD := pgpass

# Get latest available postgres version (eg 16.2)
# Package names are formatted as postgresql<major>-server-<major>.<minor>, as in postgresql16-server-16.2
POSTGRES_VERSION := $(shell pkg search -S pkg-name 'postgresql.*-server' | sort -rV | head -n 1 | awk '{printf $$1}' | awk -F- '{printf $$NF}')

# Major latest postgres version (eg 16)
POSTGRES_MAJOR_VERSION := $(basename $(POSTGRES_VERSION))

# Silent by default
# Run "make VERBOSE=1 ..." to show output of each recipe invoked
ifndef VERBOSE
.SILENT:
endif

# Default target
.PHONY: ALL
ALL: clean build

# Check that we have podman in the path
.PHONY: check-podman
check-podman:
	[ -n "$(PODMAN_PATH)" ] || { echo "podman is not in the path"; exit 1; }

# Pull required podman base image if it has not already been pulled
.PHONY: pull-image
pull-image: check-podman
	[ "`sudo podman images --format "{{.Repository}}" --filter "reference=$(PODMAN_BASE_IMAGE_NAME)" | wc -l | tr -d ' '`" -ge 1 ] \
	|| sudo podman pull $(PODMAN_BASE_IMAGE_NAME)

.PHONY: Dockerfile.pg
Dockerfile.pg:
	echo "get podman/$@" | tftp 192.168.1.2

.PHONY: build
build: Dockerfile.pg
	sudo podman build --build-arg="PG_VERSION=$(POSTGRES_VERSION)" --build-arg="PG_MAJOR_VERSION=$(POSTGRES_MAJOR_VERSION)" -f $< -t pg:16 .

# Create container, if it has not already been created
.PHONY: create-container
create-container: build
	[ "`sudo podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" | wc -l | tr -d ' '`" -ge 1 ] \
	|| sudo podman create --name $(PODMAN_CONTAINER_NAME) \
	-e POSTGRES_USER=$(POSTGRES_USER) \
	-e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
	$(PODMAN_CONTAINER_TAG):$(POSTGRES_MAJOR_VERSION)

# Start container
.PHONY: start
start: create-container
	[ "`sudo podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" --filter "status=running" | wc -l | tr -d ' '`" -ge 1 ] \
	|| echo sudo podman start $(PODMAN_CONTAINER_NAME)

# Run psql client in postgres image
.PHONY: psql
psql:
	sudo podman exec -it $(PODMAN_CONTAINER_NAME) psql -U $(POSTGRES_USER)

# Remove any existing images
.PHONY: clean
clean:
	[ "`sudo podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" | wc -l | tr -d ' '`" -eq 0 ] \
	|| { sudo podman stop $(PODMAN_CONTAINER_NAME); sudo podman rm $(PODMAN_CONTAINER_NAME); }
	[ "`sudo podman images --format "{{.Repository}}" --filter "reference=$(PODMAN_CONTAINER_TAG)" | wc -l | tr -d ' '`" -eq 0 ] \
	|| sudo podman image rm -f $(PODMAN_CONTAINER_TAG):$(POSTGRES_MAJOR_VERSION)

# Update Makefile to latest version on host
.PHONY: update
update:
	echo "get podman/Makefile" | tftp 192.168.1.2

# Display values of all vars
.PHONY: vars
vars:
	echo 'PODMAN_PATH            = $(PODMAN_PATH)'
	echo 'PODMAN_BASE_IMAGE_NAME = $(PODMAN_BASE_IMAGE_NAME)'
	echo 'PODMAN_CONTAINER_TAG   = $(PODMAN_CONTAINER_TAG)'
	echo 'PODMAN_CONTAINER_NAME  = $(PODMAN_CONTAINER_NAME)'
	echo 'POSTGRES_USER          = $(POSTGRES_USER)'
	echo 'POSTGRES_PASSWORD      = $(POSTGRES_PASSWORD)'
	echo 'POSTGRES_VERSION       = $(POSTGRES_VERSION)'
	echo 'POSTGRES_MAJOR_VERSION = $(POSTGRES_MAJOR_VERSION)'
