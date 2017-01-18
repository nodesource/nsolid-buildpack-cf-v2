#!/bin/sh

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../../.. && pwd )"
VERSION=`cat $PROJECT_DIR/VERSION`
VERSION_NSOLID=`cat $PROJECT_DIR/VERSION.nsolid`

BUILDPACK_NAME=nsolid_buildpack
BUILDPACK_FILE=$PROJECT_DIR/$BUILDPACK_NAME-v$VERSION.zip
BUILDPACK_BUNF=$PROJECT_DIR/$BUILDPACK_NAME-bundled-v$VERSION.zip

download_nsolid() {
  local VERSION_NSOLID=$1
  local VERSION_LTS=$2
  local dir=$3

  local NSOLID_URL="https://s3-us-west-2.amazonaws.com/nodesource-public-downloads/$VERSION_NSOLID/artifacts/bundles/nsolid-bundle-v$VERSION_NSOLID-linux-x64/nsolid-v$VERSION_NSOLID-$VERSION_LTS-linux-x64.tar.gz"
  local NSOLID_TARBALL="nsolid-$VERSION_NSOLID-$VERSION_LTS.tar.gz"
  local BUNDLE_NSOLID_TARBALL="$dir/$NSOLID_TARBALL"

  echo downloading $NSOLID_URL
  curl $NSOLID_URL --silent --fail --retry 5 --retry-max-time 15 -o $BUNDLE_NSOLID_TARBALL
  if [ $? -ne 0 ]; then
    echo "wops ... unable to download file, does it exist?"
    exit 1
  fi
}

download_headers() {
  local VERSION_NSOLID=$1
  local VERSION_LTS=$2
  local dir=$3

  local HEADER_URL="https://s3-us-west-2.amazonaws.com/nodesource-public-downloads/$VERSION_NSOLID/artifacts/headers/$VERSION_LTS/v$VERSION_NSOLID/nsolid-v$VERSION_NSOLID-headers.tar.gz"
  local HEADER_TARBALL="nsolid-headers-$VERSION_NSOLID-$VERSION_LTS.tar.gz"
  local BUNDLE_HEADER_TARBALL="$dir/$HEADER_TARBALL"

  echo downloading $HEADER_URL
  curl $HEADER_URL --silent --fail --retry 5 --retry-max-time 15 -o $BUNDLE_HEADER_TARBALL
  if [ $? -ne 0 ]; then
    echo "wops ... unable to download file, does it exist?"
    exit 1
  fi
}

echo 'running standard ...'
cd lib/vendor/nsolid

standard -v
if [ $? -ne 0 ]; then
  echo "wops ... need to standard-ize! ('npm i -g standard', if you haven't already)"
  exit 1
fi

cd ../../..

# build bundled buildpack

mkdir -p $PROJECT_DIR/dependencies
rm -rf   $PROJECT_DIR/dependencies/*

download_nsolid "$VERSION_NSOLID" "argon" "$PROJECT_DIR/dependencies"
download_nsolid "$VERSION_NSOLID" "boron" "$PROJECT_DIR/dependencies"

download_headers "$VERSION_NSOLID" "argon" "$PROJECT_DIR/dependencies"
download_headers "$VERSION_NSOLID" "boron" "$PROJECT_DIR/dependencies"

echo "building bundled buildpack $BUILDPACK_NAME"
BUNDLE_GEMFILE=cf.Gemfile bundle exec buildpack-packager --uncached

if [ ! -f "$BUILDPACK_FILE" ]; then
  echo "wops ... expecting to find $BUILDPACK_FILE, but not found"
  exit 1
fi

cp $BUILDPACK_FILE $BUILDPACK_BUNF

rm -rf   $PROJECT_DIR/dependencies

# build unbundled buildpack

echo "building unbundled buildpack $BUILDPACK_NAME"
BUNDLE_GEMFILE=cf.Gemfile bundle exec buildpack-packager --uncached

if [ ! -f "$BUILDPACK_FILE" ]; then
  echo "wops ... expecting to find $BUILDPACK_FILE, but not found"
  exit 1
fi
