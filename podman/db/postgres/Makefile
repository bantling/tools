# Postgres Makefile

#### Change Make defaults

# Turn off default rules
.SUFFIXES:

# Silent, run "make VERBOSE=1 ..." to show output of each recipe invoked
ifndef VERBOSE
.SILENT:
endif

# Execute recipes with shell flags -eu, where:
# -e means die if any command fails with non-zero status
# -u means die if an undefined shell variable is referenced
.SHELLFLAGS := -eu

#### Variables

# Postgres image ref - see https://hub.docker.com/_/postgres for tags
PG_IMAGE_NAME := postgres
PG_IMAGE_VER  := latest
PG_IMAGE_REF  := $(PG_IMAGE_NAME):$(PG_IMAGE_VER)

# generated image
DEPLOY_IMAGE_NAME := postgres_db
DEPLOY_IMAGE_VER  := 1.0
DEPLOY_IMAGE_REF  := $(DEPLOY_IMAGE_NAME):$(DEPLOY_IMAGE_VER)

# Dir of env source code (DML only)
SRC_ENV     := local
SRC_ENV_DIR := $(if $(SRC_ENV),src-env/$(SRC_ENV),)
SRC_ENV_ARG := $(if $(SRC_ENV),--build-arg "SRC_ENV_DIR=$(SRC_ENV_DIR)",)

# Database name, and app_exec user password
DB_NAME           := pg_app
POSTGRES_PASSWORD := postgres
APP_EXEC_PASS     := pg_app_pass

#### Targets

# Default target
.PHONY: all
all: vars podman oci

# Ensure podman is up so we can use it to build containers
.PHONY: podman
podman: podman-path podman-machine-init podman-machine-start

# Ensure podman is in the path
.PHONY: podman-path
podman-path:
	echo ">>> Checking if podman is in path"
	which podman > /dev/null 2> /dev/null || { \
	  echo "podman is not installed, or not in your path"; \
	  exit 1; \
	}

# Ensure podman has been initialzed
.PHONY: podman-machine-init
podman-machine-init:
	echo ">>> Checking of podman has been intialized"
	[ "`podman machine list --format "{{.Name}}" | wc -l`" -ge 1 ] || { \
	  echo "Initializing podman"; \
	  podman machine init; \
	}

# Ensure podman has been started 
.PHONY: podman-machine-start
podman-machine-start:
	echo ">>> Checking if podman has been started"
	[ "`podman machine list --format "{{.LastUp}}" | grep -i running | wc -l`" -ge 1 ] || { \
	  echo "Starting podman"; \
	  podman machine start; \
	}

# Ensure all oci container building operations are performed, so we have all the containers we need to run the app
.PHONY: oci
oci: oci-clean oci-pull oci-build oci-run

# Clean oci artifacts: remove all containers related to the image, and the image itself
# The only thing not removed is the base image needed to build the code
.PHONY: oci-clean
oci-clean:
	echo ">>> Cleaning previously generated Postgres OCI images and containers"
	for id in `podman ps -a --format '{{.ID}} {{.Image}}' | grep $(DEPLOY_IMAGE_REF) | awk '{print $$1}'`; \
	do \
	  echo "Removing container $$id"; \
	  podman rm -f "$$id"; \
	done
	for id in `podman image ls --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep $(DEPLOY_IMAGE_REF) | awk '{print $$1}'`; \
	do \
	  echo "Removing image $$id"; \
	  podman image rm "$$id"; \
	done

# Pull oci postgres image
.PHONY: oci-pull
oci-pull:
	echo ">>> Checking if postgres image needs to be pulled"
	[ "`podman image list --format "{{.ID}}" --filter "reference=$(PG_IMAGE_REF)" | wc -l`" -gt 0 ] || { \
	  echo "Pulling compile image"; \
	  podman pull $(PG_IMAGE_REF); \
	}

# Always build Containerfile in case args have changed
.PHONY: .Containerfile
.Containerfile: Containerfile.in
	echo ">>> Generating $@"
	cp $< $@
	if [ -n "$(SRC_ENV_ARG)" ]; then sed 's,.SRC_ENV_DIR ,,' $@ > $@.tmp; mv $@.tmp $@; fi

# Build oci image
# Pruning removes the unnamed initial stage images of multi stage builds
.PHONY: oci-build
oci-build: .Containerfile
	echo ">>> Building postgres image"
	podman build \
	  --build-arg "PG_IMAGE_REF=$(PG_IMAGE_REF)" \
	  --build-arg "APP_EXEC_PASS=$(APP_EXEC_PASS)" \
	  $(SRC_ENV_ARG) \
	  -f $< \
	  -t $(DEPLOY_IMAGE_REF) \
	  .
	podman system prune -f

# Run oci image
# If there are no errors, "database system is ready to accept connections" occurs twice
# If there are errors, "database system is ready to accept connections" occurs once, followed by ERROR line
.PHONY: oci-run
oci-run:
	echo ">>> Running postgres container"
	podman create --name=$(DEPLOY_IMAGE_NAME) -e POSTGRES_DB=$(DB_NAME) -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)" -p 5432:5432 $(DEPLOY_IMAGE_REF)
	podman start $(DEPLOY_IMAGE_NAME)
	while true; do \
	  sleep 1; \
	  printf "."; \
	  [ "`podman logs $(DEPLOY_IMAGE_NAME) 2>&1 | grep "database system is ready to accept connections" | wc -l`" -lt 1 ] || { \
	    break; \
	  }; \
	done
	while true; do \
	  sleep 1; \
	  printf "."; \
	  [ "`podman logs $(DEPLOY_IMAGE_NAME) 2>&1 | grep "ERROR" | wc -l`" -lt 1 ] || { \
	    echo; \
	    podman logs $(DEPLOY_IMAGE_NAME); \
	    exit 1; \
	  }; \
	  [ "`podman logs $(DEPLOY_IMAGE_NAME) 2>&1 | grep "database system is ready to accept connections" | wc -l`" -lt 2 ] || { \
	    break; \
	  }; \
	done
	echo
	echo "Database $(DEPLOY_IMAGE_REF) started"

# Run psql inside running postgres container
.PHONY: oci-cli
oci-cli:
	podman exec -it $(DEPLOY_IMAGE_NAME) psql -U postgres -d $(DB_NAME)

# Run baash inside running postgres container
.PHONY: oci-bash
oci-bash:
	podman exec -it $(DEPLOY_IMAGE_NAME) /bin/bash

.PHONY: vars
vars:
	echo ">>> Displaying variables"
	echo "PG_IMAGE_NAME      = $(PG_IMAGE_NAME)"
	echo "PG_IMAGE_VER       = $(PG_IMAGE_VER)"
	echo "PG_IMAGE_REF       = $(PG_IMAGE_REF)"
	echo "DEPLOY_IMAGE_NAME  = $(DEPLOY_IMAGE_NAME)"
	echo "DEPLOY_IMAGE_VER   = $(DEPLOY_IMAGE_VER)" 
	echo "DEPLOY_IMAGE_REF   = $(DEPLOY_IMAGE_REF)"
	echo "SRC_ENV            = $(SRC_ENV)"
	echo "SRC_ENV_DIR        = $(SRC_ENV_DIR)"
	echo "SRC_ENV_ARG        = $(SRC_ENV_ARG)"
	echo "DB_NAME            = $(DB_NAME)"
	echo "POSTGRES_PASSWORD  = $(POSTGRES_PASSWORD)"
	echo "APP_EXEC_PASS      = ${APP_EXEC_PASS}"