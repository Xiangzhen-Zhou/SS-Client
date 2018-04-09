#!/bin/bash

# Create the keychain with a password
security create-keychain -p travis mac-build.keychain

# Make the custom keychain default, so xcodebuild will use it for signing
security default-keychain -s mac-build.keychain

# Unlock the keychain
security unlock-keychain -p travis mac-build.keychain

# Add certificates to keychain and allow codesign to access them
security import Scripts/Certs/zxz_er.cer -k ~/Library/Keychains/mac-build.keychain -T /usr/bin/codesign
security import Scripts/Certs/zxz_er.p12 -k ~/Library/Keychains/mac-build.keychain -P $CERT_PWD -T /usr/bin/codesign

security set-key-partition-list -S apple-tool:,apple: -s -k travis mac-build.keychain