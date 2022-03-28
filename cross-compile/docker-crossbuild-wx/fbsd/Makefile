# Build a docker image of freebsd on a zfs root.
# Run a docker container and use it to create an image containing a zfs image.
# Can't do this using docker build because images cannot access loopback devices, but containers can.

# FreeBSD version
# Latest means to examine the website and determine the latest image to download.
# Otherwise, it must be major.minor >= 11.2, as that is earliest version thgat provides prebuilt images. 
FREEBSD_VERSION := latest

.PHONY: all
all: build-docker-image

# Ensure we have alpine:latest docker image pulled in
.PHONY: have-alpine-latest
.SILENT: have-alpine-latest
have-alpine-latest:
	[ -n "`docker images -q --filter=reference=alpine:latest`" ] || \
	  docker pull alpine:latest

# Verify the freebsd version is valid.
# Read all versions available from https://download.freebsd.org/releases/VM-IMAGES/ in reverse order (newest first).
# If FREEBSD_VERSION = latest (default), pick first version in the list.
# Otherwise, check each available version for a match, and complain if no match is found.
.PHONY: build-docker-image
.SILENT: build-docker-image
build-docker-image: have-alpine-latest
	versions="`curl -sL https://download.freebsd.org/releases/VM-IMAGES/ | grep -Po '(?<=href=")[^/]*' | sed '/^[^0-9]/d;s/-RELEASE//' | tac`"; \
	for version in $$versions; do \
	  if [ "$(FREEBSD_VERSION)" = "latest" -o "$(FREEBSD_VERSION)" = "$$version" ]; then \
	    found=1; \
	    break; \
      fi; \
    done; \
    [ "$$found" -eq 1 ] || { echo 'FreeBSD version $(FREEBSD_VERSION) is not valid, choices are "$$versions"'; exit 1; }; \
    echo "Building docker image for FreeBSD version $$version"; \
	docker build -t freebsd:$(FREEBSD_VERSION) --build-arg FREEBSD_VERSION=$$version .
