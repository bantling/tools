# SPDX-License-Identifier: Apache-2.0
# Make a docker container named multiarch/crossbuild-wx based on multiarch/crossbuild

# Default target
.PHONY: all
all: .docker-multiarch.crossbuild-wx 

# Pull multiarch/crossbuild if we don't already have it
.PHONY:
.docker-multiarch.crossbuild:
	if [ "`docker images -q --filter "reference=multiarch/crossbuild:latest" | wc -l`" -eq 0 ]; then \
	  docker pull multiarch/crossbuild; \
	fi

# Build multiarch/crossbuild-wx if it does not exist, or changes have been made to the Dockerfile
.PHONY:
.docker-multiarch.crossbuild-wx: .docker-multiarch.crossbuild
	docker build -t multiarch/crossbuild-wx .
