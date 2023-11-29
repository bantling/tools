# Create and run a postgres podman container with our scripts in it

# Path to podman, if we have it
PODMAN_PATH       := $(shell which podman 2> /dev/null || :)

# The podman image name for latest postgres
PODMAN_IMAGE_NAME := $(shell grep FROM Dockerfile | awk '{print $$2}' || :)

# The podman container tag
PODMAN_CONTAINER_TAG := pg-json

# The podman container name
PODMAN_CONTAINER_NAME := pg-json

# The postgres user name
POSTGRES_USER := pguser

# The postgres user password
POSTGRES_PASSWORD := pgpass

.PHONY: all
all: create-container

.PHONY: build
build: pull-image
	[ "`podman images --format "{{.Repository}}" --filter "reference=$(PODMAN_CONTAINER_TAG)" | wc -l`" -ge 1 ] \
	|| podman build -t $(PODMAN_CONTAINER_TAG) .

# Pull required podman image if it has not already been pulled
.PHONY: pull-image
pull-image: check-podman
	[ "`podman images --format "{{.Repository}}" --filter "reference=$(PODMAN_IMAGE_NAME)" | wc -l`" -ge 1 ] \
	|| podman pull $(PODMAN_IMAGE_NAME)

.PHONY: check-podman
check-podman:
	[ -n "$(PODMAN_PATH)" ] || { echo "podman is not in the path"; exit 1; }

# Create container if it has not already been created
.PHONY: create-container
create-container: build
	[ "`podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" | wc -l`" -ge 1 ] \
	|| podman create --name $(PODMAN_CONTAINER_NAME) \
	-e POSTGRES_USER=$(POSTGRES_USER) \
	-e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
	$(PODMAN_CONTAINER_TAG)

.PHONY: run
run: create-container
	[ -z "`podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" --filter "status=running" | wc -l | tr -d ' '`" ] \
	|| podman start $(PODMAN_CONTAINER_NAME)

# Run psql client in postgres image
.PHONY: psql
psql: create-container
	podman exec -it $(PODMAN_CONTAINER_NAME) psql -U $(POSTGRES_USER)
