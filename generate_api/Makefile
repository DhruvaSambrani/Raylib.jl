EXTENSION?=json
FORMAT?=JSON
REF = tags/6.0
#REF = heads/master

.PHONY: all parse clean raylib_api setup update_api

# Determine PLATFORM_OS
# No uname.exe on MinGW!, but OS=Windows_NT on Windows!
# ifeq ($(UNAME),Msys) -> Windows
ifeq ($(OS),Windows_NT)
    PLATFORM_OS = WINDOWS
else
    UNAMEOS = $(shell uname)
    ifeq ($(UNAMEOS),Linux)
        PLATFORM_OS = LINUX
    endif
    ifeq ($(UNAMEOS),FreeBSD)
        PLATFORM_OS = BSD
    endif
    ifeq ($(UNAMEOS),OpenBSD)
        PLATFORM_OS = BSD
    endif
    ifeq ($(UNAMEOS),NetBSD)
        PLATFORM_OS = BSD
    endif
    ifeq ($(UNAMEOS),DragonFly)
        PLATFORM_OS = BSD
    endif
    ifeq ($(UNAMEOS),Darwin)
        PLATFORM_OS = OSX
    endif
endif

# Define default C compiler: CC
#------------------------------------------------------------------------------------------------
CC = gcc
ifeq ($(PLATFORM_OS),OSX)
    # OSX default compiler
    CC = clang
endif
ifeq ($(PLATFORM_OS),BSD)
    # FreeBSD, OpenBSD, NetBSD, DragonFly default compiler
    CC = clang
endif

# Define default make program: MAKE
#------------------------------------------------------------------------------------------------
MAKE ?= make
ifeq ($(PLATFORM_OS),WINDOWS)
    MAKE = mingw32-make
endif

# Define compiler flags: CFLAGS
#------------------------------------------------------------------------------------------------
CFLAGS = -Wall -std=c99
#CFLAGS += -Wextra -Wmissing-prototypes -Wstrict-prototypes

ifeq ($(BUILD_MODE),DEBUG)
    CFLAGS += -g -D_DEBUG
else
    ifeq ($(PLATFORM_OS),OSX)
        CFLAGS += -O2
    else
        CFLAGS += -s -O2
    endif
endif
ifeq ($(PLATFORM_OS),WINDOWS)
    # NOTE: The resource .rc file contains windows executable icon and properties
    CFLAGS += rlparser.rc.data
endif

rlparser.c:
	curl -L https://github.com/raysan5/raylib/raw/refs/$(REF)/tools/rlparser/rlparser.c -o rlparser.c

rlparser: rlparser.c
	$(CC) rlparser.c -o rlparser $(CFLAGS)

raylib_api: sources/raylib.h rlparser
	FORMAT=JSON EXTENSION=json $(MAKE) raylib_api.json

raylib_api.$(EXTENSION): sources/raylib.h rlparser
	./rlparser -i sources/raylib.h -o raylib_api.$(EXTENSION) -f $(FORMAT) -d RLAPI

raymath_api.$(EXTENSION): sources/raymath.h rlparser
	./rlparser -i sources/raymath.h -o raymath_api.$(EXTENSION) -f $(FORMAT) -d RMAPI

rlgl_api.$(EXTENSION): sources/rlgl.h rlparser
	./rlparser -i sources/rlgl.h -o rlgl_api.$(EXTENSION) -f $(FORMAT) -d RLAPI -t "RLGL IMPLEMENTATION"

raygui_api.$(EXTENSION): sources/raygui.h rlparser
	./rlparser -i sources/raygui.h -o raygui_api.$(EXTENSION) -f $(FORMAT) -d RAYGUIAPI -t "RAYGUI IMPLEMENTATION"

parse: raylib_api.$(EXTENSION) raymath_api.$(EXTENSION) rlgl_api.$(EXTENSION) raygui_api.$(EXTENSION)

setup: sources/raylib.h sources/raymath.h sources/rlgl.h sources/raygui.h

sources:
	mkdir -p sources

sources/raylib.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/$(REF)/src/raylib.h -o sources/raylib.h

sources/raymath.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/$(REF)/src/raymath.h -o sources/raymath.h

sources/rlgl.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/$(REF)/src/rlgl.h -o sources/rlgl.h

sources/rgestures.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/$(REF)/src/rgestures.h -o sources/rgestures.h

sources/raygui.h: | sources
	curl -L https://github.com/raysan5/raygui/raw/refs/heads/master/src/raygui.h -o sources/raygui.h



# `make parse` (and therefore `make all) requires raygui.h to exist in the source directory
# API files for individual headers can be created likeso, provided the relevant header exists:
#     FORMAT=JSON EXTENSION=json make raygui_api.json
all: rlparser setup
	FORMAT=JSON EXTENSION=json $(MAKE) parse

update_api: all
	cp *.json ../api_reference

clean:
	rm -rf rlparser *.json sources rlparser.c
