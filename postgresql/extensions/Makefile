# Create and run a postgres podman container with our scripts in it

# Path to podman, if we have it
PODMAN_PATH       := $(shell which podman 2> /dev/null || :)

# The podman image name for latest postgres
PODMAN_IMAGE_NAME := $(shell grep FROM Dockerfile | awk '{print $$2}' || :)

# The podman container tag
PODMAN_CONTAINER_TAG := pg-extensions

# The podman container name
PODMAN_CONTAINER_NAME := pg-extensions

# The postgres user name
POSTGRES_USER := pguser

# The postgres user password
POSTGRES_PASSWORD := pgpass

.PHONY: all
all: start

# Start container
.PHONY: start
start: create-container
	[ "`podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" --filter "status=running" | wc -l | tr -d ' '`" -ge 1 ] \
	|| podman start $(PODMAN_CONTAINER_NAME)

# Create container, if it has not already been created
.PHONY: create-container
create-container: build
	[ "`podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" | wc -l | tr -d ' '`" -ge 1 ] \
	|| podman create --name $(PODMAN_CONTAINER_NAME) \
		-e POSTGRES_USER=$(POSTGRES_USER) \
		-e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
		$(PODMAN_CONTAINER_TAG)

# Build a new image, removing any existing image first
.PHONY: build
build: pull-image
	[ "`podman images --format "{{.Repository}}" --filter "reference=$(PODMAN_CONTAINER_TAG)" | wc -l | tr -d ' '`" -eq 0 ] \
	|| podman image rm -f $(PODMAN_CONTAINER_TAG)
	podman build -t $(PODMAN_CONTAINER_TAG) .

# Pull required podman base image if it has not already been pulled
.PHONY: pull-image
pull-image: check-podman
	[ "`podman images --format "{{.Repository}}" --filter "reference=$(PODMAN_IMAGE_NAME)" | wc -l | tr -d ' '`" -ge 1 ] \
	|| podman pull $(PODMAN_IMAGE_NAME)

# Check that we have podman in the path
.PHONY: check-podman
check-podman:
	[ -n "$(PODMAN_PATH)" ] || { echo "podman is not in the path"; exit 1; }

# Run psql client in postgres image
.PHONY: psql
psql: start
	podman exec -it $(PODMAN_CONTAINER_NAME) psql -U $(POSTGRES_USER)

# Clean up all generated artifacts
.PHONY: clean
clean:
	[ "`podman ps -a --format "{{.Names}}" --filter "name=$(PODMAN_CONTAINER_NAME)" | wc -l | tr -d ' '`" -eq 0 ] \
	|| podman stop $(PODMAN_CONTAINER_NAME)
	[ "`podman images --format "{{.Repository}}" --filter "reference=$(PODMAN_CONTAINER_TAG)" | wc -l | tr -d ' '`" -eq 0 ] \
	|| podman image rm -f $(PODMAN_CONTAINER_TAG)
