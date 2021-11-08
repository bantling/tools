# Windows Makefile
# Note the symbol WINDOWS can be tested for in source code

# This is the only variable to change per project, it is the name of the executables
# The debug executable   will be $(DEBUG_APP_DIR)/$(APP_NAME).exe
# The release executable will be $(RELEASE_APP_DIR)/$(APP_NAME).exe
APP_NAME            := myapp

INC                 := $(wildcard include/all/*.h) $(wildcard include/windows/*.h)
SRC_ALL             := $(wildcard src/all/*.cpp)
SRC_WIN             := $(wildcard src/windows/*.cpp)
COMPILER            := /usr/bin/x86_64-w64-mingw32-g++
CPP_OPTS            := -std=c++14 -Wall -Wextra -pedantic -Wshadow -Weffc++ -Werror -c -MMD -DWINDOWS
BUILD               := build/win
DEBUG_CPP_OPTS      := -g -DDEBUG
DEBUG_DIR_ALL       := $(BUILD)/debug/all
DEBUG_DIR_WINDOWS   := $(BUILD)/debug/windows
DEBUG_OBJ_ALL       := $(SRC_ALL:src/all/%.cpp=$(DEBUG_DIR_ALL)/%.o)
DEBUG_OBJ_WINDOWS   := $(SRC_WIN:src/windows/%.cpp=$(DEBUG_DIR_WINDOWS)/%.o)
DEBUG_APP_DIR       := $(BUILD_DIR)/app/debug
DEBUG_APP           := $(DEBUG_APP_DIR)/$(APP_NAME).exe
DEBUG_APP_OPTS      := /usr/x86_64-w64-mingw32/lib/libstdc++.a \
                       /usr/x86_64-w64-mingw32/lib/libwinpthread.a
RELEASE_CPP_OPTS    :=
RELEASE_DIR_ALL     := $(BUILD)/release/all
RELEASE_DIR_WINDOWS := $(BUILD)/release/windows
RELEASE_OBJ_ALL     := $(SRC_ALL:src/all/%.cpp=$(RELEASE_DIR_ALL)/%.o)
RELEASE_OBJ_WINDOWS := $(SRC_WIN:src/win/%.cpp=$(RELEASE_DIR_WINDOWS)/%.o)
RELEASE_APP_DIR     := $(BUILD_DIR)/app/release
RELEASE_APP         := $(RELEASE_APP_DIR)/$(APP_NAME).exe
RELEASE_APP_OPTS    := /usr/x86_64-w64-mingw32/lib/libstdc++.a \
                       /usr/x86_64-w64-mingw32/lib/libwinpthread.a

# Default target
.PHONY: all
all: $(DEBUG_APP) $(RELEASE_APP)

# Debug app
$(DEBUG_APP): $(DEBUG_OBJ_ALL) $(DEBUG_OBJ_WINDOWS)
	$(COMPILER) -static -s -o $@ $(DEBUG_OBJ_ALL) $(DEBUG_LIBS)

$(DEBUG_DIR_ALL)/%.o: $(SRC_ALL) $(DEBUG_DIR_ALL)
	$(COMPILER) $(CPP_OPTS) $(DEBUG_CPP_OPTS) $< -o $@

$(DEBUG_DIR_WINDOWS)/%.o: $(SRC_WIN) $(DEBUG_DIR_WINDOWS)
	$(COMPILER) $(CPP_OPTS) $(DEBUG_CPP_OPTS) $< -o $@

$(DEBUG_DIR_ALL):
	mkdir -p $@

$(DEBUG_DIR_WINDOWS):
	mkdir -p $@

# Release app
$(RELEASE_APP): $(RELEASE_OBJ_ALL) $(RELEASE_OBJ_WINDOWS)
	$(COMPILER) -static -s -o $@ $(RELEASE_OBJ_ALL) $(RELEASE_LIBS)

$(RELEASE_DIR_ALL)/%.o: $(SRC_ALL) $(RELEASE_DIR_ALL)
	$(COMPILER) $(CPP_OPTS) $(RELEASE_CPP_OPTS) $< -o $@

$(RELEASE_DIR_WINDOWS)/%.o: $(SRC_WIN) $(RELEASE_DIR_WINDOWS)
	$(COMPILER) $(CPP_OPTS) $(RELEASE_CPP_OPTS) $< -o $@

$(RELEASE_DIR_ALL):
	mkdir -p $@

$(RELEASE_DIR_WINDOWS):
	mkdir -p $@

# Copy the windows executables and required runtime files to a target folder.
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
	rm -rf $(BUILD) || :

# Generate the echo lines for win-vars target
# This target shd be run if any vars are added or removed.
# It modifies this makefile, assuming that all lines beginning with >
# are at the end of the file.
.PHONY: vars-generate
.SILENT: vars-generate
vars-generate:
	mf='Makefile'; \
	sed -i '/^>/,$$d' $$mf; \
	echo '>echo "==== Windows vars ===="' >> $$mf; \
	grep '^[A-Z].*:=' $$mf | \
	sed -r 's/([^ ]*)( *):=.*/>echo "\1\2= \$$\(\1\)"/' >> $$mf; \
	echo -e "\\n.RECIPEPREFIX =" >> $$mf

.PHONY: vars
.SILENT: vars
.RECIPEPREFIX = >
vars:
>echo "==== Windows vars ===="
>echo "APP_NAME            = $(APP_NAME)"
>echo "INC                 = $(INC)"
>echo "SRC_ALL             = $(SRC_ALL)"
>echo "SRC_WIN             = $(SRC_WIN)"
>echo "COMPILER            = $(COMPILER)"
>echo "CPP_OPTS            = $(CPP_OPTS)"
>echo "BUILD               = $(BUILD)"
>echo "DEBUG_CPP_OPTS      = $(DEBUG_CPP_OPTS)"
>echo "DEBUG_DIR_ALL       = $(DEBUG_DIR_ALL)"
>echo "DEBUG_DIR_WINDOWS   = $(DEBUG_DIR_WINDOWS)"
>echo "DEBUG_OBJ_ALL       = $(DEBUG_OBJ_ALL)"
>echo "DEBUG_OBJ_WINDOWS   = $(DEBUG_OBJ_WINDOWS)"
>echo "DEBUG_APP_DIR       = $(DEBUG_APP_DIR)"
>echo "DEBUG_APP           = $(DEBUG_APP)"
>echo "DEBUG_APP_OPTS      = $(DEBUG_APP_OPTS)"
>echo "RELEASE_CPP_OPTS    = $(RELEASE_CPP_OPTS)"
>echo "RELEASE_DIR_ALL     = $(RELEASE_DIR_ALL)"
>echo "RELEASE_DIR_WINDOWS = $(RELEASE_DIR_WINDOWS)"
>echo "RELEASE_OBJ_ALL     = $(RELEASE_OBJ_ALL)"
>echo "RELEASE_OBJ_WINDOWS = $(RELEASE_OBJ_WINDOWS)"
>echo "RELEASE_APP_DIR     = $(RELEASE_APP_DIR)"
>echo "RELEASE_APP         = $(RELEASE_APP)"
>echo "RELEASE_APP_OPTS    = $(RELEASE_APP_OPTS)"

.RECIPEPREFIX =
