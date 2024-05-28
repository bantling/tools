# Build a native freebsd postgres container image

.PHONY: ALL
ALL: clean build

.PHONY: clean
clean:
	[ `sudo podman images | grep pg | wc -l` -eq 0 ] || sudo podman image rm pg

.pgversion:
	pkg search -S pkg-name 'postgres.*-server' | sort -rV | head -n 1 | awk '{print $$1}' | echo -n > $@

.PHONY: Dockerfile.pg
Dockerfile.pg: .pgversion
	echo "get podman/Dockerfile" | tftp 192.168.1.2

.PHONY: build
build: Dockerfile.pg
	sudo podman build -f $< -t pg:`cat .pgversion` .
