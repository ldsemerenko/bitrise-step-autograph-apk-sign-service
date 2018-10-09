#!/bin/bash
set -e

#THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

apk_path=${BITRISE_APK_PATH}
SIGNED_APK_PATHS=()

#split source path with "|" into an string array
IFS='|' read -ra apkPaths <<< "${apk_path}"
#foreach apkpath
for i in "${apkPaths[@]}"; do
  if [ ! -f ${i} ]; then
    echo "APK not found: ${i}"
    continue
  fi

  apkBasename=$(basename "${i}")
  if [[ ! ${apkBasename} == *"unsigned"* ]]; then
    echo "APK not unsigned: ${apkBasename}"
    continue
  fi

  apkBasePath=$(dirname "${i}")
  signedApkName="${apkBasename/unsigned/signed-aligned}"

  #   setup output signed-aligned-apkpath
  signedApkPath="${apkBasePath}/${signedApkName}"

  #   upload with curl and output with output path
  curl -H "Authorization: ${token}" -F "input=@${i}" -o "${signedApkPath}" ${endpoint}

  #   add output path to signed-apkpath array
  SIGNED_APK_PATHS+="${signedApkPath}"
done

#join signed-apkpath with "|"
BITRISE_SIGNED_APK_PATH=$(IFS=\| ; echo "${SIGNED_APK_PATHS[*]}")
echo "APK Signed: ${BITRISE_SIGNED_APK_PATH}"
BITRISE_APK_PATH="${BITRISE_SIGNED_APK_PATH}|${BITRISE_APK_PATH}"
echo "APK Origin: ${BITRISE_APK_PATH}"

#write joined into output variable
envman add --key BITRISE_SIGNED_APK_PATH --value "${BITRISE_SIGNED_APK_PATH}"
envman add --key BITRISE_APK_PATH --value "${BITRISE_APK_PATH}"
