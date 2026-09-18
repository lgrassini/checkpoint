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

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Packaging/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Done: ${APP_BUNDLE}"
