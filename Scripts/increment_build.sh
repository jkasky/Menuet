#!/bin/sh

plistFile=${1:-"${PROJECT_DIR}/${INFOPLIST_FILE}"}
buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$plistFile")
buildNumber=$(($buildNumber + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$plistFile"
