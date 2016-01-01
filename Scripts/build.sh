#!/bin/bash

export PATH=$PATH:/usr/local/bin
cd `git rev-parse --show-toplevel`

brew update > /dev/null || exit 1
brew update carthage || brew install carthage || exit 1
brew update xctool || brew install xctool || exit 1

xcodebuild -version | grep "Xcode 7" > /dev/null || { echo 'Not running Xcode 7' ; exit 1; }

carthage update --configuration Release --platform Mac
# Note we don't build iOS on device due to code signing requirements.
# xctool -project SwiftIO.xcodeproj -scheme "All" -sdk iphonesimulator build test || exit $!
xctool -project SwiftIO.xcodeproj -scheme "SwiftIO_OSX" -sdk macosx build test || exit $!
