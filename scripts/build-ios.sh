#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/prepare-ios.py
xcodebuild -project ios/Fishbot.xcodeproj -scheme Fishbot -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -archivePath build/Fishbot.xcarchive CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO archive
mkdir -p build/package/Payload
cp -R build/Fishbot.xcarchive/Products/Applications/Fishbot.app build/package/Payload/
cd build/package
ditto -c -k --sequesterRsrc --keepParent Payload Fishbot-unsigned.ipa
shasum -a 256 Fishbot-unsigned.ipa > Fishbot-unsigned.ipa.sha256
echo "Unsigned IPA ready. Personal signing is required before installation."
