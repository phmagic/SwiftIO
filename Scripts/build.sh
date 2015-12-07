#!/bin/bash

export PATH=$PATH:/usr/local/bin

cd `git rev-parse --show-toplevel`

brew list xctool || brew install xctool
brew list carthage || brew install carthage
carthage bootstrap
xcodebuild -version | grep "Xcode 7" > /dev/null || { echo 'Not running Xcode 7' ; exit 1; }
xctool -project SwiftIO.xcodeproj -scheme All build test || exit $!
