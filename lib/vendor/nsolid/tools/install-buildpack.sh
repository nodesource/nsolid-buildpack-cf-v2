#!/bin/sh

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../../.. && pwd )"
VERSION=`cat $PROJECT_DIR/VERSION`

BUILDPACK_NAME=nsolid_buildpack
BUILDPACK_FILE=nsolid_buildpack-v$VERSION.zip

if [ ! -f "$BUILDPACK_FILE" ]; then
  echo "wops ... expecting to find $BUILDPACK_FILE, but not found"
  exit 1
fi

echo ""
echo "logging in as admin into PCFdev"
cf login -u admin -p admin -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation

echo ""
echo "installing buildpack $BUILDPACK_NAME"
cf update-buildpack $BUILDPACK_NAME -p $BUILDPACK_FILE -i 100

echo ""
echo "logging in as user  into PCFdev"
cf login -u user  -p pass  -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation
