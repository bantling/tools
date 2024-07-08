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

# The absolute path and dir to this Makefile
THIS_MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MAKEFILE_DIR  := $(patsubst %/,%,$(dir $(THIS_MAKEFILE_PATH)))

# Postgres image ref - see https://hub.docker.com/_/postgres for tags
PG_IMAGE_NAME := postgres
PG_IMAGE_VER  := latest
PG_IMAGE_REF  := $(PG_IMAGE_NAME):$(PG_IMAGE_VER)

# generated image
DEPLOY_IMAGE_NAME := postgres_db
DEPLOY_IMAGE_VER  := 1.0
DEPLOY_IMAGE_REF  := $(DEPLOY_IMAGE_NAME):$(DEPLOY_IMAGE_VER)

# Dir of source code (DDL and DML used to init the database)
SRC_DIR := $(THIS_MAKEFILE_DIR)/src

# Database name, and app_exec user password
DB_NAME           := pg_app
POSTGRES_PASSWORD := postgres
APP_EXEC_PASS     := pg_app_pass

#### Targets

# Default target
.PHONY: all
all: vars oci

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

# Build oci image
# Pruning removes the unnamed initial stage images of multi stage builds
.PHONY: oci-build
oci-build: Containerfile
	echo ">>> Building postgres image"
	podman build \
	  --build-arg "PG_IMAGE_REF=$(PG_IMAGE_REF)" \
	  --build-arg "APP_EXEC_PASS=$(APP_EXEC_PASS)" \
	  -t $(DEPLOY_IMAGE_REF) \
	  .
	podman system prune -f

# Run oci image
.PHONY: oci-run
oci-run:
	echo ">>> Running postgres container"
	podman create --name=$(DEPLOY_IMAGE_NAME) -e POSTGRES_DB=$(DB_NAME) -e POSTGRES_PASSWORD="$(POSTGRES_PASSWORD)" -p 5432:5432 $(DEPLOY_IMAGE_REF)
	podman start $(DEPLOY_IMAGE_NAME)

# Run psql inside running postgres container
.PHONY: oci-sql-cli
oci-sql-cli:
	podman exec -it $(DEPLOY_IMAGE_NAME) psql -U postgres -d $(DB_NAME)

.PHONY: vars
vars:
	echo ">>> Displaying variables"
	echo "THIS_MAKEFILE_PATH = $(THIS_MAKEFILE_PATH)"
	echo "THIS_MAKEFILE_DIR  = $(THIS_MAKEFILE_DIR)"
	echo "PG_IMAGE_NAME      = $(PG_IMAGE_NAME)"
	echo "PG_IMAGE_VER       = $(PG_IMAGE_VER)"
	echo "PG_IMAGE_REF       = $(PG_IMAGE_REF)"
	echo "DEPLOY_IMAGE_NAME  = $(DEPLOY_IMAGE_NAME)"
	echo "DEPLOY_IMAGE_VER   = $(DEPLOY_IMAGE_VER)" 
	echo "DEPLOY_IMAGE_REF   = $(DEPLOY_IMAGE_REF)"
	echo "SRC_DIR            = $(SRC_DIR)"
	echo "DB_NAME            = $(DB_NAME)"
	echo "POSTGRES_PASSWORD  = $(POSTGRES_PASSWORD)"
	echo "APP_EXEC_PASS      = ${APP_EXEC_PASS}"
