#!/bin/bash
set -euo pipefail

APP_NAME="ImperatorPong"
APP_BUNDLE="Imperator Pong.app"

echo "Building ${APP_NAME}..."
swift build -c release 2>&1

echo "Creating app bundle..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/"

echo "Signing app bundle..."
codesign --sign - --force --deep "${APP_BUNDLE}"

echo ""
echo "Build complete: ${APP_BUNDLE}"
echo "Run with: open '${APP_BUNDLE}'"
