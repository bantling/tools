# Demo of using podman on Windows, Mac, or Linux

# Turn off default Make rules
.SUFFIXES:

#### Variables

# golang docker image ref
IMAGE_REF = "docker.io/library/golang"

#### Targets

# Default target
.PHONY: all
all: pull generate build run

# Pull docker image
.PHONY: pull
.SILENT: pull
pull:
	[ `podman image list --format "{{.ID}}" --filter "reference=$(IMAGE_REF)" | wc -l` -eq 1 ] || podman pull $(IMAGE_REF)

# Generate artifacts
.PHONY: generate
generate: hello.go Dockerfile

# Create go source file
.SILENT: hello.go
hello.go:
	echo Generating hello.go
	echo -e 'package main\n\
\n\
import "fmt"\n\
\n\
func main() {\n\
  fmt.Println("Hello,World")\n\
}\n\
' | sed 's/^-e //;/^\\$$/d' > $@

# Create Dockerfile
.SILENT: Dockerfile
Dockerfile:
	echo Generating Dockerfile
	echo -e 'FROM $(IMAGE_REF)\n\
COPY hello.go /hello.go\n\
RUN go build /hello.go\n\
ENTRYPOINT ./hello\n\
' | sed 's/^-e //;/^\\$$/d' > $@

# Build docker image
build: hello.go Dockerfile
	podman build -t hello:1.0 .
	@touch build

# Run docker image
.PHONY: run
run:
	podman run --rm hello:1.0

# Clean artifacts: delete generated files, remove all containers related to the image, and the image itself
# The only thing not removed is the golang container needed to build the code
.PHONY: clean
.SILENT: clean
clean:
	rm -f hello.go Dockerfile build
	for id in `podman ps -a --format "{{.ID}} {{.Image}}" | grep hello:1.0 | awk '{print $$1}'`; do \
		echo "Removing container $$id"; \
		podman rm "$$id"; \
	done
	for id in `podman image ls --format '{{.ID}} {{.Repository}}:{{.Tag}}' | grep hello:1.0 | awk '{print $$1}'`; do \
		echo "Removing image $$id"; \
		podman image rm "$$id"; \
	done
