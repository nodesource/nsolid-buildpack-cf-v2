#!/bin/sh

VERSION=$1

BUILDPACK_NAME=nsolid_buildpack
BUILDPACK_FILE=nsolid_buildpack-v$VERSION.zip

if [ "x$VERSION" == "x" ]; then
  echo "wops ... need to pass the version of the buildpack, eg, 1.0.0"
  exit 1
fi

# Build the nsolid buildpack and install into PCFdev.
# Should be run in the root project directory.

echo 'running standard ...'
cd lib/vendor/nsolid

standard -v
if [ $? -ne 0 ]; then
  echo "wops ... need to standard-ize! ('npm i -g standard', if you haven't already)"
  exit 1
fi

cd ../../..

echo "building buildpack $BUILDPACK_NAME"
BUNDLE_GEMFILE=cf.Gemfile bundle exec buildpack-packager --uncached

if [ ! -f "$BUILDPACK_FILE" ]; then
  echo "wops ... expecting to find $BUILDPACK_FILE, but not found"
  exit 1
fi

echo ""
echo "logging in as admin"
cf login -u admin -p admin -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation

echo ""
echo "installing buildpack $BUILDPACK_NAME"
cf update-buildpack $BUILDPACK_NAME -p nsolid_buildpack-v1.0.0.zip -i 100

echo ""
echo "logging back in as user"
cf login -u user  -p pass  -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation
