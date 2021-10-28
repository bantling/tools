# Make for all platforms

# Build all platforms
.PHONY: all
all: linux-all windows-all

# Include all platforms sub makefiles
include Makefile.linux
include Makefile.windows

# Clean all platforms
.PHONY: clean
clean:
	rm -rf build || :

# Generate vars for all platforms
.PHONY: vars-generate
vars-generate: linux-vars-generate windows-vars-generate

# Display vars for all platforms
.PHONY: display-vars
display-vars: linux-vars windows-vars

# Page vars for all platforms using more
.PHONY: vars
vars:
	$(MAKE) -s display-vars | more
