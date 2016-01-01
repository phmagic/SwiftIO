#!/bin/bash

export PATH=$PATH:/usr/local/bin

# Run from git project root.
cd `git rev-parse --show-toplevel`

# Check we're on current version of Xcode.
xcodebuild -version | grep "Xcode 7.2" > /dev/null || { echo 'Not running Xcode 7.2' ; exit 1; }

# Update brew, carthage and xctool.
brew update > /dev/null || exit 1
brew update carthage || brew install carthage || exit 1
brew update xctool || brew install xctool || exit 1

# Note we don't build iOS due to code signing requirements.

# Install dependencies
carthage bootstrap --configuration Release --platform Mac

xctool -project SwiftIO.xcodeproj -scheme "SwiftIO_OSX" -sdk macosx build test || exit $!
xctool -project SwiftIO.xcodeproj -scheme "TestApp" -sdk macosx build || exit $!
