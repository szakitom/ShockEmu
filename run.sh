#!/bin/bash
# Run ./build.sh <mapping.se> and ./resign.sh first.
cd "$(dirname "$0")"

APP="${REMOTEPLAY_APP:-$PWD/RemotePlay-ShockEmu.app}"
BIN="$APP/Contents/MacOS/RemotePlay"
FIFO=/tmp/gpad-daemon-data

if [ ! -d "$APP" ]; then
	echo "$APP does not exist. Run ./resign.sh to create the patched local copy."
	exit 1
fi

if ! codesign -d --entitlements - --xml "$APP" 2>/dev/null | grep -q "allow-dyld-environment-variables"; then
	echo "$APP still carries the hardened-runtime signature, so macOS will strip"
	echo "DYLD_INSERT_LIBRARIES and the injection will be silently ignored."
	echo "Run ./resign.sh first."
	exit 1
fi

clean() {
	rm -f "$FIFO"
	killall gpad-daemon 2>/dev/null
	echo "Program terminated"
}
trap clean EXIT INT

rm -f "$FIFO"
mkfifo "$FIFO"
./gpad-daemon &

# No DYLD_FORCE_FLAT_NAMESPACE: on macOS 11+ it no longer redirects imports that
# resolve into the dyld shared cache. iohid_wrap.dylib uses __DATA,__interpose
# instead, which dyld still honours.
DYLD_INSERT_LIBRARIES="$PWD/iohid_wrap.dylib" "$BIN"
