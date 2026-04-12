EXTENSION?=json
FORMAT?=JSON
VERSION = 5.5

.PHONY: all parse clean raylib_api setup update_api


raylib_parser: raylib_parser.c
	cc raylib_parser.c -o raylib_parser

raylib_api: sources/raylib.h raylib_parser
	FORMAT=JSON EXTENSION=json $(MAKE) raylib_api.json

raylib_api.$(EXTENSION): sources/raylib.h raylib_parser
	./raylib_parser -i sources/raylib.h -o raylib_api.$(EXTENSION) -f $(FORMAT) -d RLAPI

raymath_api.$(EXTENSION): sources/raymath.h raylib_parser
	./raylib_parser -i sources/raymath.h -o raymath_api.$(EXTENSION) -f $(FORMAT) -d RMAPI

rlgl_api.$(EXTENSION): sources/rlgl.h raylib_parser
	./raylib_parser -i sources/rlgl.h -o rlgl_api.$(EXTENSION) -f $(FORMAT) -d RLAPI -t "RLGL IMPLEMENTATION"

rcamera_api.$(EXTENSION): sources/rcamera.h raylib_parser
	./raylib_parser -i sources/rcamera.h -o rcamera_api.$(EXTENSION) -f $(FORMAT) -d RLAPI -t "rcamera IMPLEMENTATION"

reasings_api.$(EXTENSION): ../examples/others/reasings.h raylib_parser
	./raylib_parser -i ../examples/others/reasings.h -o reasings_api.$(EXTENSION) -f $(FORMAT) -d EASEDEF

rmem_api.$(EXTENSION): sources/rmem.h raylib_parser
	./raylib_parser -i sources/rmem.h -o rmem_api.$(EXTENSION) -f $(FORMAT) -d RMEMAPI -t "RMEM IMPLEMENTATION"

physac_api.$(EXTENSION): sources/physac.h raylib_parser
	./raylib_parser -i sources/physac.h -o physac_api.$(EXTENSION) -f $(FORMAT) -d PHYSACDEF -t "PHYSAC IMPLEMENTATION"

raygui_api.$(EXTENSION): sources/raygui.h raylib_parser
	./raylib_parser -i sources/raygui.h -o raygui_api.$(EXTENSION) -f $(FORMAT) -d RAYGUIAPI -t "RAYGUI IMPLEMENTATION"

parse: raylib_api.$(EXTENSION) raymath_api.$(EXTENSION) rlgl_api.$(EXTENSION) rmem_api.$(EXTENSION) physac_api.$(EXTENSION) raygui_api.$(EXTENSION) rcamera_api.$(EXTENSION)

setup: sources/raylib.h sources/raymath.h sources/rlgl.h sources/raygui.h sources/rmem.h sources/physac.h sources/rcamera.h

sources:
	mkdir -p sources

sources/raylib.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/tags/$(VERSION)/src/raylib.h -o sources/raylib.h

sources/raymath.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/tags/$(VERSION)/src/raymath.h -o sources/raymath.h

sources/rlgl.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/tags/$(VERSION)/src/rlgl.h -o sources/rlgl.h

sources/rcamera.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/tags/$(VERSION)/src/rcamera.h -o sources/rcamera.h

sources/rgestures.h: | sources
	curl -L https://github.com/raysan5/raylib/raw/refs/tags/$(VERSION)/src/rgestures.h -o sources/rgestures.h

sources/raygui.h: | sources
	curl -L https://github.com/raysan5/raygui/raw/refs/heads/master/src/raygui.h -o sources/raygui.h

sources/rmem.h: | sources
	curl -L https://github.com/raylib-extras/rmem/raw/refs/heads/main/src/rmem.h -o sources/rmem.h

sources/physac.h: | sources
	curl -L https://github.com/victorfisac/Physac/raw/refs/heads/master/src/physac.h -o sources/physac.h



# `make parse` (and therefore `make all) requires
# rmem.h, physac.h and raygui.h to exist in the source directory
# API files for individual headers can be created likeso, provided the relevant header exists:
#     FORMAT=JSON EXTENSION=json make raygui_api.json
all: raylib_parser setup
	FORMAT=JSON EXTENSION=json $(MAKE) parse

update_api: all
	cp *.json ../api_reference

clean:
	rm -f raylib_parser *.json
