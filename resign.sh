#!/bin/bash
# PS Remote Play ships with the hardened runtime enabled, which makes dyld strip
# every DYLD_* variable at launch -- DYLD_INSERT_LIBRARIES is silently ignored.
#
# Rather than touch Sony's install, this makes a local copy of the app and
# re-signs *that* ad-hoc with entitlements that permit injection.
# /Applications/RemotePlay.app is left completely untouched, so PS Remote Play
# keeps working normally and updates as usual.
#
# To undo: rm -rf ./RemotePlay-ShockEmu.app
set -e

cd "$(dirname "$0")"

SRC="${1:-/Applications/RemotePlay.app}"
DST="$PWD/RemotePlay-ShockEmu.app"

[ -d "$SRC" ] || { echo "Not found: $SRC"; exit 1; }

echo "Copying $SRC -> $DST"
rm -rf "$DST"
cp -R "$SRC" "$DST"

ENT="$(mktemp -t shockemu-ent)"
{
	echo '<?xml version="1.0" encoding="UTF-8"?>'
	echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
	echo '<plist version="1.0">'
	echo '<dict>'
	echo '	<key>com.apple.security.device.audio-input</key><true/>'
	echo '	<key>com.apple.security.cs.disable-library-validation</key><true/>'
	echo '	<key>com.apple.security.cs.allow-dyld-environment-variables</key><true/>'
	echo '	<key>com.apple.security.cs.allow-unsigned-executable-memory</key><true/>'
	echo '	<key>com.apple.security.cs.allow-jit</key><true/>'
	echo '</dict>'
	echo '</plist>'
} > "$ENT"

echo "Re-signing the copy ad-hoc ..."
codesign --force --deep --sign - --options runtime --entitlements "$ENT" "$DST"
rm -f "$ENT"

echo
if codesign -d --entitlements - --xml "$DST" 2>/dev/null | grep -q "allow-dyld-environment-variables"; then
	echo "OK. ./RemotePlay-ShockEmu.app will accept ShockEmu; $SRC is unchanged."
	echo "Note: the copy has a different code signature, so it has its own"
	echo "keychain/TCC identity -- expect to sign in to PSN again inside it."
else
	echo "WARNING: entitlements did not apply."
	exit 1
fi
