# Install tools necessary for cross compiling
# - dockerhub container multiarch/crossbuild, to get support for linux, windows, osx
# - github build for a freebsd docker container

.PHONY: all
all: multiarch freebsd

.PHONY: multiarch
.SILENT: multiarch
multiarch:
	docker images --format '{{.Repository}}:{{.Tag}}' | \
	grep -q multiarch/crossbuild:latest || \
	docker pull multiarch/crossbuild:latest

.PHONY: freebsd
.SILENT: freebsd
freebsd:
	docker images --format '{{.Repository}}:{{.Tag}}' | \
	grep -q freebsd-cross-build:9.3 || { \
		echo getit; \
	}
	