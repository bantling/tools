# OS X Makefile

# This is the only variable to change per project, it is the name of the executables
# The debug executable   will be $(DEBUG_APP_DIR)/$(APP_NAME)
# The release executable will be $(RELEASE_APP_DIR)/$(APP_NAME)

#docker run -it --rm -v $(pwd):/workdir -e CROSS_TRIPLE=x86_64-apple-darwin multiarch/crossbuild bash -c "make -f make/osx/Makefile; chown -R `id -u`:`id -g` make/osx/build"

APP_NAME          := myapp

MAKEFILE_PATH    := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR     := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))
BASE_DIR         := $(patsubst %/,%,$(dir $(patsubst %/,%,$(dir $(patsubst %/,%,$(MAKEFILE_DIR))))))
INC              := $(wildcard $(BASE_DIR)/include/all/*.h) $(wildcard $(BASE_DIR)/include/osx/*.h)
SRC_ALL          := $(wildcard $(BASE_DIR)/src/all/*.cpp)
SRC_OSX          := $(wildcard $(BASE_DIR)/src/osx/*.cpp)
COMPILER         := c++
CPP_OPTS         := -std=c++14 -Wall -Wextra -pedantic -Wshadow -Weffc++ -Werror -c -MMD -DOSX
BUILD_DIR        := $(MAKEFILE_DIR)/build
DEBUG_CPP_OPTS   := -g -DDEBUG
DEBUG_DIR_ALL    := $(BUILD_DIR)/debug/all
DEBUG_DIR_OSX    := $(BUILD_DIR)/debug/osx
DEBUG_OBJ_ALL    := $(SRC_ALL:$(BASE_DIR)/src/all/%.cpp=$(DEBUG_DIR_ALL)/%.o)
DEBUG_OBJ_OSX    := $(SRC_OSX:$(BASE_DIR)/src/osx/%.cpp=$(DEBUG_DIR_OSX)/%.o)
DEBUG_APP_DIR    := $(BUILD_DIR)/app/debug
DEBUG_APP        := $(DEBUG_APP_DIR)/$(APP_NAME)
DEBUG_APP_OPTS   := 
RELEASE_CPP_OPTS :=
RELEASE_DIR_ALL  := $(BUILD_DIR)/release/all
RELEASE_DIR_OSX  := $(BUILD_DIR)/release/osx
RELEASE_OBJ_ALL  := $(SRC_ALL:$(BASE_DIR)/src/all/%.cpp=$(RELEASE_DIR_ALL)/%.o)
RELEASE_OBJ_OSX  := $(SRC_OSX:$(BASE_DIR)/src/osx/%.cpp=$(RELEASE_DIR_OSX)/%.o)
RELEASE_APP_DIR  := $(BUILD_DIR)/app/release
RELEASE_APP      := $(RELEASE_APP_DIR)/$(APP_NAME)
RELEASE_APP_OPTS := 

# Default target
.PHONY: all
all: $(DEBUG_APP) $(RELEASE_APP)

# Debug app
$(DEBUG_APP): $(DEBUG_OBJ_ALL) $(DEBUG_OBJ_OSX) $(DEBUG_APP_DIR)
	$(COMPILER) $(DEBUG_APP_OPTS) -o $@ $(DEBUG_OBJ_ALL)

$(DEBUG_DIR_ALL)/%.o: $(SRC_ALL) $(DEBUG_DIR_ALL)
	$(COMPILER) $(CPP_OPTS) $(DEBUG_CPP_OPTS) $< -o $@

$(DEBUG_DIR_OSX)/%.o: $(SRC_OSX) $(DEBUG_DIR_OSX)
	$(COMPILER) $(CPP_OPTS) $(DEBUG_CPP_OPTS) $< -o $@

$(DEBUG_DIR_ALL):
	mkdir -p $@

$(DEBUG_DIR_OSX):
	mkdir -p $@

$(DEBUG_APP_DIR):
	mkdir -p $@

# Release app
$(RELEASE_APP): $(RELEASE_OBJ_ALL) $(RELEASE_OBJ_OSX) $(RELEASE_APP_DIR)
	$(COMPILER) $(RELEASE_APP_OPTS) -o $@ $(RELEASE_OBJ_ALL)

$(RELEASE_DIR_ALL)/%.o: $(SRC_ALL) $(RELEASE_DIR_ALL)
	$(COMPILER) $(CPP_OPTS) $(RELEASE_CPP_OPTS) $< -o $@

$(RELEASE_DIR_OSX)/%.o: $(SRC_OSX) $(RELEASE_DIR_OSX)
	$(COMPILER) $(CPP_OPTS) $(RELEASE_CPP_OPTS) $< -o $@

$(RELEASE_DIR_ALL):
	mkdir -p $@

$(RELEASE_DIR_OSX):
	mkdir -p $@

$(RELEASE_APP_DIR):
	mkdir -p $@

# Copy the osx executables and required runtime files to a target folder.
# Set make var COPY to target location.
.PHONY: copy
copy:
	[ -n "$(COPY)" ] || { echo "COPY must be set to target dir"; exit 1; }; \
	[ -d "$(DEBUG_APP_DIR)" ]   && cp -r "$(DEBUG_APP_DIR)"   "$(COPY)"; \
	[ -d "$(RELEASE_APP_DIR)" ] && cp -r "$(RELEASE_APP_DIR)" "$(COPY)"; \

# Clean the artifacts
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

# Generate the echo lines for lin-vars target
# This target shd be run if any vars are added or removed.
# It modifies this makefile, assuming that all lines beginning with >
# are at the end of the file.
.PHONY: vars-generate
.SILENT: vars-generate
vars-generate:
	mf='Makefile'; \
	sed -i '/^>/,$$d' $$mf; \
	echo '>echo "==== Linux vars ===="' >> $$mf; \
	grep '^[A-Z].*:=' $$mf | \
	sed -r 's/([^ ]*)( *):=.*/>echo "\1\2= \$$\(\1\)"/' >> $$mf; \
	echo -e "\\n.RECIPEPREFIX =" >> $$mf

.PHONY: vars
.SILENT: vars
.RECIPEPREFIX = >
vars:
>echo "==== OSX vars ===="
>echo "APP_NAME          = $(APP_NAME)"
>echo "MAKEFILE_PATH    = $(MAKEFILE_PATH)"
>echo "MAKEFILE_DIR     = $(MAKEFILE_DIR)"
>echo "BASE_DIR         = $(BASE_DIR)"
>echo "INC              = $(INC)"
>echo "SRC_ALL          = $(SRC_ALL)"
>echo "SRC_OSX          = $(SRC_OSX)"
>echo "COMPILER         = $(COMPILER)"
>echo "CPP_OPTS         = $(CPP_OPTS)"
>echo "BUILD_DIR        = $(BUILD_DIR)"
>echo "DEBUG_CPP_OPTS   = $(DEBUG_CPP_OPTS)"
>echo "DEBUG_DIR_ALL    = $(DEBUG_DIR_ALL)"
>echo "DEBUG_DIR_OSX    = $(DEBUG_DIR_OSX)"
>echo "DEBUG_OBJ_ALL    = $(DEBUG_OBJ_ALL)"
>echo "DEBUG_OBJ_OSX    = $(DEBUG_OBJ_OSX)"
>echo "DEBUG_APP_DIR    = $(DEBUG_APP_DIR)"
>echo "DEBUG_APP        = $(DEBUG_APP)"
>echo "DEBUG_APP_OPTS   = $(DEBUG_APP_OPTS)"
>echo "RELEASE_CPP_OPTS = $(RELEASE_CPP_OPTS)"
>echo "RELEASE_DIR_ALL  = $(RELEASE_DIR_ALL)"
>echo "RELEASE_DIR_OSX  = $(RELEASE_DIR_OSX)"
>echo "RELEASE_OBJ_ALL  = $(RELEASE_OBJ_ALL)"
>echo "RELEASE_OBJ_OSX  = $(RELEASE_OBJ_OSX)"
>echo "RELEASE_APP_DIR  = $(RELEASE_APP_DIR)"
>echo "RELEASE_APP      = $(RELEASE_APP)"
>echo "RELEASE_APP_OPTS = $(RELEASE_APP_OPTS)"

.RECIPEPREFIX =
