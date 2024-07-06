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

# Database name
DB_NAME := pg_app

#### Targets

# Default target
.PHONY: all
all: vars oci

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
