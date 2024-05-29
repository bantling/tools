# // SPDX-License-Identifier: Apache-2.0

# Build a native freebsd postgres container image

# Silent by default
# Run "make VERBOSE=1 ..." to show output of each recipe invoked
.ifndef VERBOSE
.SILENT:
.endif

.PHONY: ALL
ALL: clean build

.PHONY: update
update:
	echo "get podman/Makefile" | tftp 192.168.1.2

.PHONY: clean
clean:
	[ `sudo podman images | grep pg | wc -l` -eq 0 ] || sudo podman image rm pg

.pgversion:
	pkgName="`pkg search -S pkg-name 'postgres.*-server' | sort -rV | head -n 1 | awk '{printf $$1}'`"; \
	pgVer="`echo $$pkgName | sed -r 's/[^0-9]*([0-9]+)*.*/\1/'`"; \
	echo -e "$$pkgName\n$$pgVer" > $@

.PHONY: Dockerfile.pg
Dockerfile.pg: .pgversion
	echo "get podman/$@" | tftp 192.168.1.2

.PHONY: build
build: Dockerfile.pg
	sudo podman build --build-arg="PG_VERSION=16" -f $? -t pg:16 .
