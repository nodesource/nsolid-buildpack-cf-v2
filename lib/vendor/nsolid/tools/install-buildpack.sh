#!/bin/sh

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../../.. && pwd )"
VERSION=`cat $PROJECT_DIR/VERSION`

BUILDPACK_UNAME=nsolid_buildpack
BUILDPACK_UFILE=nsolid_buildpack-v$VERSION.zip

BUILDPACK_BNAME=nsolid_buildpack-bundled
BUILDPACK_BFILE=nsolid_buildpack-bundled-v$VERSION.zip

if [ ! -f "$BUILDPACK_UFILE" ]; then
  echo "wops ... expecting to find $BUILDPACK_UFILE, but not found"
  exit 1
fi

echo ""
echo "logging in as admin into PCFdev"
cf login -u admin -p admin -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation

echo ""
echo "installing buildpack $BUILDPACK_UNAME"
cf update-buildpack $BUILDPACK_UNAME -p $BUILDPACK_UFILE -i 100

echo ""
echo "installing buildpack $BUILDPACK_BNAME"
cf update-buildpack $BUILDPACK_BNAME -p $BUILDPACK_BFILE -i 100

echo ""
echo "logging in as user  into PCFdev"
cf login -u user  -p pass  -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation
