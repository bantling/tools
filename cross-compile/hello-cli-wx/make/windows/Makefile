# SPDX-License-Identifier: Apache-2.0
# Windows Makefile

PLATFORM_LC          := windows
APP_NAME             := app.exe

PLATFORM_UC          := $(shell echo $(PLATFORM_LC) | tr a-z A-Z)
MAKEFILE_PATH        := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR         := $(patsubst %/,%,$(dir $(MAKEFILE_PATH)))
BASE_DIR             := $(patsubst %/,%,$(dir $(patsubst %/,%,$(dir $(patsubst %/,%,$(MAKEFILE_DIR))))))
INC                  := $(patsubst %/,-I%,$(dir $(wildcard $(BASE_DIR)/include/all/*.h) $(wildcard $(BASE_DIR)/include/$(PLATFORM_LC)/*.h)))
SRC_ALL_DIR          := $(BASE_DIR)/src/all
SRC_ALL              := $(wildcard $(SRC_ALL_DIR)/*.cpp)
SRC_PLATFORM_DIR     := $(BASE_DIR)/src/$(PLATFORM_LC)
SRC_PLATFORM         := $(wildcard $(SRC_PLATFORM_DIR)/*.cpp)
COMPILER             := c++
COMPILE_OPTS         := -std=c++14 -Wall -Wextra -pedantic -Wshadow -Weffc++ -Werror -c -MMD -D$(PLATFORM_UC)
BUILD_DIR            := $(MAKEFILE_DIR)/build
DEBUG_COMPILE_OPTS   := -g -DDEBUG
DEBUG_DIR_ALL        := $(BUILD_DIR)/debug/all
DEBUG_DIR_PLATFORM   := $(BUILD_DIR)/debug/$(PLATFORM_LC)
DEBUG_OBJ_ALL        := $(SRC_ALL:$(BASE_DIR)/src/all/%.cpp=$(DEBUG_DIR_ALL)/%.o)
DEBUG_OBJ_PLATFORM   := $(SRC_PLATFORM:$(BASE_DIR)/src/$(PLATFORM_LC)/%.cpp=$(DEBUG_DIR_PLATFORM)/%.o)
DEBUG_APP_DIR        := $(BUILD_DIR)/app/debug
DEBUG_APP            := $(DEBUG_APP_DIR)/$(APP_NAME)
DEBUG_APP_OPTS       := -static
RELEASE_COMPILE_OPTS :=
RELEASE_DIR_ALL      := $(BUILD_DIR)/release/all
RELEASE_DIR_PLATFORM := $(BUILD_DIR)/release/$(PLATFORM_LC)
RELEASE_OBJ_ALL      := $(SRC_ALL:$(BASE_DIR)/src/all/%.cpp=$(RELEASE_DIR_ALL)/%.o)
RELEASE_OBJ_PLATFORM := $(SRC_PLATFORM:$(BASE_DIR)/src/$(PLATFORM_LC)/%.cpp=$(RELEASE_DIR_PLATFORM)/%.o)
RELEASE_APP_DIR      := $(BUILD_DIR)/app/release
RELEASE_APP          := $(RELEASE_APP_DIR)/$(APP_NAME)
RELEASE_APP_OPTS     := -static -s

# Default target
.PHONY: all
all: $(DEBUG_APP) $(RELEASE_APP)

# Debug app
$(DEBUG_APP): $(DEBUG_OBJ_ALL) $(DEBUG_OBJ_PLATFORM) | $(DEBUG_APP_DIR)
	$(COMPILER) -o $@ $(DEBUG_OBJ_ALL) $(DEBUG_OBJ_PLATFORM) $(DEBUG_APP_OPTS)

$(DEBUG_DIR_ALL)/%.o: $(SRC_ALL_DIR)/%.cpp | $(DEBUG_DIR_ALL)
	$(COMPILER) $(COMPILE_OPTS) $(DEBUG_COMPILE_OPTS) $(INC) $< -o $@

$(DEBUG_DIR_PLATFORM)/%.o: $(SRC_PLATFORM_DIR)/%.cpp | $(DEBUG_DIR_PLATFORM)
	$(COMPILER) $(COMPILE_OPTS) $(DEBUG_COMPILE_OPTS) $(INC) $< -o $@

$(DEBUG_DIR_ALL):
	mkdir -p $@

$(DEBUG_DIR_PLATFORM):
	mkdir -p $@

$(DEBUG_APP_DIR):
	mkdir -p $@

# Release app
$(RELEASE_APP): $(RELEASE_OBJ_ALL) $(RELEASE_OBJ_PLATFORM) | $(RELEASE_APP_DIR)
	$(COMPILER) -o $@ $(RELEASE_OBJ_ALL) $(RELEASE_OBJ_PLATFORM) $(RELEASE_APP_OPTS)

$(RELEASE_DIR_ALL)/%.o: $(SRC_ALL_DIR)/%.cpp | $(RELEASE_DIR_ALL)
	$(COMPILER) $(COMPILE_OPTS) $(RELEASE_COMPILE_OPTS) $(INC) $< -o $@

$(RELEASE_DIR_PLATFORM)/%.o: $(SRC_PLATFORM_DIR)/%.cpp | $(RELEASE_DIR_PLATFORM)
	$(COMPILER) $(COMPILE_OPTS) $(RELEASE_COMPILE_OPTS) $(INC) $< -o $@

$(RELEASE_DIR_ALL):
	mkdir -p $@

$(RELEASE_DIR_PLATFORM):
	mkdir -p $@

$(RELEASE_APP_DIR):
	mkdir -p $@

# Copy the platform executables and required runtime files to a target folder.
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
	mf='$(lastword $(MAKEFILE_LIST))'; \
	sed -i '/^>/,$$d' $$mf; \
	echo '>echo "==== $$(PLATFORM_UC) vars ===="' >> $$mf; \
	grep '^[A-Z].*:=' $$mf | \
	sed -r 's/([^ ]*)( *):=.*/>echo "\1\2= \$$\(\1\)"/' >> $$mf; \
	echo -e "\\n.RECIPEPREFIX =" >> $$mf

.PHONY: vars
.SILENT: vars
.RECIPEPREFIX = >
vars:
>echo "==== $(PLATFORM_UC) vars ===="
>echo "PLATFORM_LC          = $(PLATFORM_LC)"
>echo "APP_NAME             = $(APP_NAME)"
>echo "PLATFORM_UC          = $(PLATFORM_UC)"
>echo "MAKEFILE_PATH        = $(MAKEFILE_PATH)"
>echo "MAKEFILE_DIR         = $(MAKEFILE_DIR)"
>echo "BASE_DIR             = $(BASE_DIR)"
>echo "INC                  = $(INC)"
>echo "SRC_ALL_DIR          = $(SRC_ALL_DIR)"
>echo "SRC_ALL              = $(SRC_ALL)"
>echo "SRC_PLATFORM_DIR     = $(SRC_PLATFORM_DIR)"
>echo "SRC_PLATFORM         = $(SRC_PLATFORM)"
>echo "COMPILER             = $(COMPILER)"
>echo "COMPILE_OPTS         = $(COMPILE_OPTS)"
>echo "BUILD_DIR            = $(BUILD_DIR)"
>echo "DEBUG_COMPILE_OPTS   = $(DEBUG_COMPILE_OPTS)"
>echo "DEBUG_DIR_ALL        = $(DEBUG_DIR_ALL)"
>echo "DEBUG_DIR_PLATFORM   = $(DEBUG_DIR_PLATFORM)"
>echo "DEBUG_OBJ_ALL        = $(DEBUG_OBJ_ALL)"
>echo "DEBUG_OBJ_PLATFORM   = $(DEBUG_OBJ_PLATFORM)"
>echo "DEBUG_APP_DIR        = $(DEBUG_APP_DIR)"
>echo "DEBUG_APP            = $(DEBUG_APP)"
>echo "DEBUG_APP_OPTS       = $(DEBUG_APP_OPTS)"
>echo "RELEASE_COMPILE_OPTS = $(RELEASE_COMPILE_OPTS)"
>echo "RELEASE_DIR_ALL      = $(RELEASE_DIR_ALL)"
>echo "RELEASE_DIR_PLATFORM = $(RELEASE_DIR_PLATFORM)"
>echo "RELEASE_OBJ_ALL      = $(RELEASE_OBJ_ALL)"
>echo "RELEASE_OBJ_PLATFORM = $(RELEASE_OBJ_PLATFORM)"
>echo "RELEASE_APP_DIR      = $(RELEASE_APP_DIR)"
>echo "RELEASE_APP          = $(RELEASE_APP)"
>echo "RELEASE_APP_OPTS     = $(RELEASE_APP_OPTS)"

.RECIPEPREFIX =
