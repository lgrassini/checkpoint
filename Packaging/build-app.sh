#!/bin/bash
# Assembles Checkpoint.app from the SwiftPM executable. Ad-hoc signed
# (sign-to-run-locally) since there's no Apple Developer Team yet.
#
# Usage: Packaging/build-app.sh [debug|release]
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${1:-debug}"
APP_NAME="Checkpoint"
BUILD_DIR=".build/${CONFIGURATION}"
APP_BUNDLE=".build/${APP_NAME}.app"

echo "Building ${APP_NAME} (${CONFIGURATION})..."
swift build -c "${CONFIGURATION}"

echo "Assembling ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

EXECUTABLE="${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "${BUILD_DIR}/${APP_NAME}" "${EXECUTABLE}"
cp "Packaging/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# SwiftPM records the deployment target (14.0) as the *SDK* version in the
# Mach-O build-version load command. macOS 26+ decides whether to apply the
# new design language from that SDK version, so an app reporting sdk 14.0
# renders in the legacy compatibility look (old button/control styling).
# Record the SDK it was actually compiled against instead.
MIN_OS="$(plutil -extract LSMinimumSystemVersion raw Packaging/Info.plist)"
SDK_VERSION="$(xcrun --sdk macosx --show-sdk-version)"
echo "Setting build version: minos ${MIN_OS}, sdk ${SDK_VERSION}..."
vtool -set-build-version macos "${MIN_OS}" "${SDK_VERSION}" \
    -replace -output "${EXECUTABLE}.tmp" "${EXECUTABLE}"
mv "${EXECUTABLE}.tmp" "${EXECUTABLE}"
chmod +x "${EXECUTABLE}"

echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Done: ${APP_BUNDLE}"
