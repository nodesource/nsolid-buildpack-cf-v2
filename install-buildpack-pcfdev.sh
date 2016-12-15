#!/bin/sh

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSION=`cat $PROJECT_DIR/VERSION`

BUILDPACK_NAME_U=nsolid_buildpack
BUILDPACK_FILE_U=buildpacks/nsolid_buildpack-v$VERSION.zip
BUILDPACK_NAME_B=nsolid_buildpack_bundled
BUILDPACK_FILE_B=buildpacks/nsolid_buildpack-bundled-v$VERSION.zip

if [ ! -f "$BUILDPACK_FILE_U" ]; then
  echo "wops ... expecting to find $BUILDPACK_FILE_U, but not found"
  exit 1
fi

if [ ! -f "$BUILDPACK_FILE_B" ]; then
  echo "wops ... expecting to find $BUILDPACK_FILE_B, but not found"
  exit 1
fi

echo ""
echo "logging in as admin into PCFdev"
cf login -u admin -p admin -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation

echo ""
echo "updating buildpack $BUILDPACK_NAME_U"
cf update-buildpack $BUILDPACK_NAME_U -p $BUILDPACK_FILE_U -i 100

echo ""
echo "updating buildpack $BUILDPACK_NAME_B"
cf update-buildpack $BUILDPACK_NAME_B -p $BUILDPACK_FILE_B -i 100

echo ""
echo "logging in as user  into PCFdev"
cf login -u user  -p pass  -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation
