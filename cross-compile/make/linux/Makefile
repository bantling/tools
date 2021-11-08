# Linux Makefile
# Note the symbol LINUX can be tested for in source code

# This is the only variable to change per project, it is the name of the executables
# The debug executable   will be $(DEBUG_APP_DIR)/$(APP_NAME)
# The release executable will be $(RELEASE_APP_DIR)/$(APP_NAME)
APP_NAME          := myapp

INC               := $(wildcard include/all/*.h) $(wildcard include/linux/*.h)
SRC_ALL           := $(wildcard ../src/all/*.cpp)
SRC_LINUX         := $(wildcard ../src/linux/*.cpp)
COMPILER          := g++
CPP_OPTS          := -std=c++14 -Wall -Wextra -pedantic -Wshadow -Weffc++ -Werror -c -MMD -DLINUX
BUILD_DIR         := build
DEBUG_CPP_OPTS    := -g -DDEBUG
DEBUG_DIR_ALL     := $(BUILD_DIR)/debug/all
DEBUG_DIR_LINUX   := $(BUILD_DIR)/debug/linux
DEBUG_OBJ_ALL     := $(SRC_ALL:src/all/%.cpp=$(DEBUG_DIR_ALL)/%.o)
DEBUG_OBJ_LINUX   := $(SRC_LINUX:src/linux/%.cpp=$(DEBUG_DIR_LINUX)/%.o)
DEBUG_APP_DIR     := $(BUILD_DIR)/app/debug
DEBUG_APP         := $(DEBUG_APP_DIR)/$(APP_NAME)
DEBUG_APP_OPTS    :=
RELEASE_CPP_OPTS  :=
RELEASE_DIR_ALL   := $(BUILD_DIR)/release/all
RELEASE_DIR_LINUX := $(BUILD_DIR)/release/linux
RELEASE_OBJ_ALL   := $(SRC_ALL:src/all/%.cpp=$(RELEASE_DIR_ALL)/%.o)
RELEASE_OBJ_LINUX := $(SRC_LINUX:src/linux/%.cpp=$(RELEASE_DIR_LINUX)/%.o)
RELEASE_APP_DIR   := $(BUILD_DIR)/app/release
RELEASE_APP       := $(RELEASE_APP_DIR)/$(APP_NAME)
RELEASE_APP_OPTS  :=

# Default target
.PHONY: all
all: $(DEBUG_APP) $(RELEASE_APP)

# Debug app
$(DEBUG_APP): $(DEBUG_OBJ_ALL) $(DEBUG_OBJ_LINUX)
	$(COMPILER) -o $@ $(DEBUG_OBJ_ALL) $(DEBUG_APP_OPTS)

$(DEBUG_DIR_ALL)/%.o: $(SRC_ALL) $(DEBUG_DIR_ALL)
	$(COMPILER) $(CPP_OPTS) $(DEBUG_CPP_OPTS) $< -o $@

$(DEBUG_DIR_LINUX)/%.o: $(SRC_LINUX) $(DEBUG_DIR_LINUX)
	$(COMPILER) $(CPP_OPTS) $(DEBUG_CPP_OPTS) $< -o $@

$(DEBUG_DIR_ALL):
	mkdir -p $@

$(DEBUG_DIR_LINUX):
	mkdir -p $@

# Release app
$(RELEASE_APP): $(RELEASE_OBJ_ALL) $(RELEASE_OBJ_LINUX)
	$(COMPILER) -o $@ $(RELEASE_OBJ_ALL) $(RELEASE_APP_OPTS)

$(RELEASE_DIR_ALL)/%.o: $(SRC_ALL) $(RELEASE_DIR_ALL)
	$(COMPILER) $(CPP_OPTS) $(RELEASE_CPP_OPTS) $< -o $@

$(RELEASE_DIR_LINUX)/%.o: $(SRC_LINUX) $(RELEASE_DIR_LINUX)
	$(COMPILER) $(CPP_OPTS) $(RELEASE_CPP_OPTS) $< -o $@

$(RELEASE_DIR_ALL):
	mkdir -p $@

$(RELEASE_DIR_LINUX):
	mkdir -p $@

# Copy the linux executables and required runtime files to a target folder.
# Set make var COPY to target location.
.PHONY: copy
copy:
	if [ -n "$(COPY)" ]; then \
	  [ -f "$(DEBUG_APP)" ] && cp "$(DEBUG_APP)" "$(COPY)"; \
	  [ -f "$(RELEASE_APP)" ] && cp "$(RELEASE_APP)" "$(COPY)"; \
	fi

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
>echo "==== Linux vars ===="
>echo "APP_NAME          = $(APP_NAME)"
>echo "INC               = $(INC)"
>echo "SRC_ALL           = $(SRC_ALL)"
>echo "SRC_LINUX         = $(SRC_LINUX)"
>echo "COMPILER          = $(COMPILER)"
>echo "CPP_OPTS          = $(CPP_OPTS)"
>echo "BUILD_DIR         = $(BUILD_DIR)"
>echo "DEBUG_CPP_OPTS    = $(DEBUG_CPP_OPTS)"
>echo "DEBUG_DIR_ALL     = $(DEBUG_DIR_ALL)"
>echo "DEBUG_DIR_LINUX   = $(DEBUG_DIR_LINUX)"
>echo "DEBUG_OBJ_ALL     = $(DEBUG_OBJ_ALL)"
>echo "DEBUG_OBJ_LINUX   = $(DEBUG_OBJ_LINUX)"
>echo "DEBUG_APP_DIR     = $(DEBUG_APP_DIR)"
>echo "DEBUG_APP         = $(DEBUG_APP)"
>echo "DEBUG_APP_OPTS    = $(DEBUG_APP_OPTS)"
>echo "RELEASE_CPP_OPTS  = $(RELEASE_CPP_OPTS)"
>echo "RELEASE_DIR_ALL   = $(RELEASE_DIR_ALL)"
>echo "RELEASE_DIR_LINUX = $(RELEASE_DIR_LINUX)"
>echo "RELEASE_OBJ_ALL   = $(RELEASE_OBJ_ALL)"
>echo "RELEASE_OBJ_LINUX = $(RELEASE_OBJ_LINUX)"
>echo "RELEASE_APP_DIR   = $(RELEASE_APP_DIR)"
>echo "RELEASE_APP       = $(RELEASE_APP)"
>echo "RELEASE_APP_OPTS  = $(RELEASE_APP_OPTS)"

.RECIPEPREFIX =
