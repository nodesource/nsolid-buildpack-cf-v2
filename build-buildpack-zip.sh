#!/bin/sh

# delete a file, if it exists
rmIfExists() {
  local fileName=$1
  if [ -f $fileName ]; then
    rm $fileName
  fi
}

# main processing
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

VERSION_BUILDPACK=`cat $PROJECT_DIR/VERSION`
VERSION_NSOLID=`cat $PROJECT_DIR/VERSION.nsolid`

cd "$PROJECT_DIR"

echo 'running standard ...'
cd "$PROJECT_DIR/lib/vendor/nsolid"

standard -v
if [ $? -ne 0 ]; then
  echo "whoops ... need to standard-ize! ('npm i -g standard', if you haven't already)"
fi

cd "$PROJECT_DIR"

# get dependencies
mkdir -p $PROJECT_DIR/dependencies
node lib/vendor/nsolid/tools/get-dependencies.js

# build bundled buildpack
BUILDPACK_NAME=nsolid_buildpack
BUILDPACK_UFILE=$PROJECT_DIR/buildpacks/$BUILDPACK_NAME-v$VERSION_BUILDPACK.zip
BUILDPACK_BFILE=$PROJECT_DIR/buildpacks/$BUILDPACK_NAME-bundled-v$VERSION_BUILDPACK.zip

mkdir -p $PROJECT_DIR/buildpacks

rmIfExists $BUILDPACK_UFILE
rmIfExists $BUILDPACK_BFILE

echo ""
echo "building buildpacks/`basename $BUILDPACK_UFILE`"
zip -qr $BUILDPACK_UFILE \
  "bin" \
  "compile-extensions" \
  "lib" \
  "node_modules" \
  "profile" \
  "vendor" \
  "dependencies.json" \
  "manifest.yml" \
  "VERSION" \
  "VERSION.nsolid" \
  "-x" \
    "*/.git*" \
    "*/.git/*" \
    "*/test/*"

echo "building buildpacks/`basename $BUILDPACK_BFILE`"
cp "$BUILDPACK_UFILE" "$BUILDPACK_BFILE"

zip -q $BUILDPACK_BFILE dependencies/nsolid*-$VERSION_NSOLID-*.tar.gz
