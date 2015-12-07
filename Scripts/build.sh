#!/bin/bash

export PATH=$PATH:/usr/local/bin

cd `git rev-parse --show-toplevel`

# Test
xcodebuild -version | head -n 1 | grep "Xcode 7.1" || { echo "Not running correct Xcode version" ; exit 1; }

# Setup
brew list xctool || brew install xctool || exit $!
brew list carthage || brew install carthage || exit $!
carthage bootstrap --verbose || exit $!

# Run
xctool -project SwiftIO.xcodeproj -scheme All build test || exit $!
