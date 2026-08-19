#!/bin/bash
set -e

make
python3 shockemu.py "$1"
clang -dynamiclib -std=gnu99 iohid_wrap.m -current_version 1.0 -compatibility_version 1.0 \
	-lobjc -framework Foundation -framework AppKit -framework CoreFoundation -framework IOKit -o iohid_wrap.dylib

# arm64 requires every loaded image to carry a signature.
codesign --force --sign - iohid_wrap.dylib
