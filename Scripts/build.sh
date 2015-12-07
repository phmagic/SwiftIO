#!/bin/bash

export PATH=$PATH:/usr/local/bin

brew install carthage

carthage bootstrap

xcodebuild -version | grep "Xcode 7" > /dev/null || { echo 'Not running Xcode 7' ; exit 1; }

cd `git rev-parse --show-toplevel`

xctool -project SwiftIO.xcodeproj -scheme All build test || exit $!
