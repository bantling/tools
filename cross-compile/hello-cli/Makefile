# SPDX-License-Identifier: Apache-2.0
# Make for all platforms

# Optional vars to set:
# COPY: if set, copy binaries to $(COPY)/{linux,windows}

MAKE_DIRS := $(wildcard make/*)

# Build all platforms
.PHONY: all
all:
	docker run -it --rm -u "`id -u`:`id -g`" -v $$(pwd):/workdir -e CROSS_TRIPLE=x86_64-linux-gnu multiarch/crossbuild make -f make/linux/Makefile
	docker run -it --rm -u "`id -u`:`id -g`" -v $$(pwd):/workdir -e CROSS_TRIPLE=x86_64-w64-mingw32 multiarch/crossbuild make -f make/windows/Makefile
	docker run -it --rm -u "`id -u`:`id -g`" -v $$(pwd):/workdir -e CROSS_TRIPLE=x86_64-apple-darwin multiarch/crossbuild make -f make/osx/Makefile
	ssh -p 5222 localhost 'gmake -f /mnt/hello-cli/make/freebsd/Makefile' 

# Copy all platform builds
.PHONY: copy
copy:
	[ -n "$(COPY)" ] || { echo "COPY must be set to target dir"; exit 1; }; \
	for d in $(MAKE_DIRS); do \
	  dirname="$(COPY)/`basename $$d`"; \
	  mkdir -p "$$dirname"; \
	  $(MAKE) -C $$d COPY="$$dirname" copy; \
	done

# Clean all platforms
.PHONY: clean
clean:
	for d in $(MAKE_DIRS); do \
	  $(MAKE) -C $$d clean; \
	done

# Generate vars for all platforms
.PHONY: vars-generate
vars-generate:
	for d in $(MAKE_DIRS); do \
	  $(MAKE) -C $$d vars-generate; \
	done

# Display vars for all platforms
.PHONY: display-vars
display-vars:
	@echo "==== Top level Makefile ===="
	@echo "MAKE_DIRS            = $(MAKE_DIRS)"
	for d in $(MAKE_DIRS); do \
	  $(MAKE) -C $$d vars; \
	done

# Page vars for all platforms using more
.PHONY: vars
vars:
	$(MAKE) -s display-vars | more
