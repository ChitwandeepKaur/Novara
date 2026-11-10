#!/bin/bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo 'Usage: bash Scripts/install_on_iphone.sh APPLE_TEAM_ID IPHONE_DEVICE_ID'
    echo 'Find your team in Xcode > Settings > Apple Accounts.'
    echo 'Find your device ID with: xcrun devicectl list devices'
    exit 2
fi

team_id="$1"
phone_id="$2"
if [[ ! "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
    echo 'Use the 10-character development team ID shown by Xcode.'
    exit 2
fi

project_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_root"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
build_dir="${TMPDIR:-/tmp/}novara-personal-device-build"

xcodebuild -project ASCEND.xcodeproj -scheme ASCEND -configuration Debug \
    -destination "id=$phone_id" -derivedDataPath "$build_dir" \
    -allowProvisioningUpdates DEVELOPMENT_TEAM="$team_id" CODE_SIGN_STYLE=Automatic build

app_path="$build_dir/Build/Products/Debug-iphoneos/Novara.app"
if [[ ! -d "$app_path" ]]; then
    echo 'A signed iPhone app was not produced. Check Xcode signing and device setup.'
    exit 1
fi
xcrun devicectl device install app --device "$phone_id" "$app_path"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Info.plist")"
xcrun devicectl device process launch --device "$phone_id" "$bundle_id"
