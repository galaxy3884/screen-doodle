#!/bin/bash
# Builds ./draw. The overlay works around a duplicate module.modulemap
# in some Command Line Tools installs; it is harmless on healthy toolchains.
cd "$(dirname "$0")"
cat > overlay.yaml <<JSON
{"version":0,"roots":[{"name":"/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap","type":"file","external-contents":"$PWD/empty.modulemap"}]}
JSON
swiftc -O -target arm64-apple-macos12.0 -vfsoverlay overlay.yaml -Xcc -ivfsoverlay -Xcc overlay.yaml draw.swift -o draw
