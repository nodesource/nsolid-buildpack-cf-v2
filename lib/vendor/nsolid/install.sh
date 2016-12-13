#!/usr/bin/env bash

# perform some initialization tasks, before getting going
init_nsolid() {
  local BUILD_DIR=$1
  local SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  header "N|Solid initialization"
  echo 'installing cf, .profile.d/nsolid-setup.sh' | output "$LOG_FILE"

  mkdir -p $BUILD_DIR/.nsolid-bin

  cp $SCRIPT_PATH/bins/cf         $BUILD_DIR/.nsolid-bin
  cp $SCRIPT_PATH/tools/*.js      $BUILD_DIR/.nsolid-bin

  chmod +x $BUILD_DIR/.nsolid-bin/cf

  mkdir -p $BUILD_DIR/.profile.d
  cp $SCRIPT_PATH/bins/nsolid-setup.sh $BUILD_DIR/.profile.d
}

init_nsolid $1

# install the appropriate version of the N|Solid Runtime
install_nsolid() {
  # incoming version parm is the Node.js base LTS version; eg, 4.0.0 or 6.0.0
  local NODE_VERSION="$1"
  local INSTALL_DIR="$2"
  local BUILD_DIR="$3"
  local SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../.. && pwd )"
  local VERSION_NSOLID=`cat $PROJECT_PATH/VERSION.nsolid`
  local VERSION_LTS="argon"
  local VERSION_NODEX="4.x"

  if [ "$NODE_VERSION" == "6.0.0" ];
  then
    VERSION_LTS="boron"
    VERSION_NODEX="6.x"
  fi

  echo "N|Solid version $VERSION_NSOLID / $VERSION_LTS (equivalent Node.js version $VERSION_NODEX)" | output "$LOG_FILE"

  local NSOLID_URL="https://s3-us-west-2.amazonaws.com/nodesource-public-downloads/$VERSION_NSOLID/artifacts/bundles/nsolid-bundle-v$VERSION_NSOLID-linux-x64/nsolid-v$VERSION_NSOLID-$VERSION_LTS-linux-x64.tar.gz"
  local HEADER_URL="https://s3-us-west-2.amazonaws.com/nodesource-public-downloads/$VERSION_NSOLID/artifacts/headers/$VERSION_LTS/v$VERSION_NSOLID/nsolid-v$VERSION_NSOLID-headers.tar.gz"

  local NSOLID_TARBALL="nsolid-$VERSION_NSOLID-$VERSION_LTS.tar.gz"
  local BUNDLE_NSOLID_TARBALL="$PROJECT_PATH/dependencies/$NSOLID_TARBALL"
  local CACHED_NSOLID_TARBALL="$CACHE_DIR/$NSOLID_TARBALL"

  local HEADER_TARBALL="nsolid-headers-$VERSION_NSOLID-$VERSION_LTS.tar.gz"
  local BUNDLE_HEADER_TARBALL="$PROJECT_PATH/dependencies/$HEADER_TARBALL"
  local CACHED_HEADER_TARBALL="$CACHE_DIR/$HEADER_TARBALL"

  mkdir -p $CACHE_DIR

  if [ -e $BUNDLE_NSOLID_TARBALL ]; then
    echo "Using bundled N|Solid $VERSION_NSOLID/$VERSION_LTS" | output "$LOG_FILE"
    cp $BUNDLE_NSOLID_TARBALL $CACHED_NSOLID_TARBALL
  else
    if [ -e $CACHED_NSOLID_TARBALL ]; then
      echo "Using cached N|Solid $VERSION_NSOLID/$VERSION_LTS" | output "$LOG_FILE"
    else
      echo "Downloading N|Solid $VERSION_NSOLID/$VERSION_LTS..." | output "$LOG_FILE"
      echo "url: $NSOLID_URL" | output "$LOG_FILE"
      curl $NSOLID_URL --silent --fail --retry 5 --retry-max-time 15 -o $CACHED_NSOLID_TARBALL || (echo "Unable to download N|Solid $NSOLID_VERSION bundle; does it exist?" && false)
      echo "Downloaded [$NSOLID_URL]" | output "$LOG_FILE"
    fi
  fi

  echo "Extracting `basename $CACHED_NSOLID_TARBALL`" | output "$LOG_FILE"
  mkdir -p /tmp/nsolid/
  rm -rf /tmp/nsolid/*
  tar xzf $CACHED_NSOLID_TARBALL -C /tmp/nsolid --strip-components 1
  mkdir -p $INSTALL_DIR
  mv /tmp/nsolid/* $INSTALL_DIR
  chmod +x $INSTALL_DIR/bin/*

  if [ -e $BUNDLE_HEADER_TARBALL ]; then
    echo "Using bundled N|Solid headers $VERSION_NSOLID/$VERSION_LTS" | output "$LOG_FILE"
    cp $BUNDLE_HEADER_TARBALL $CACHED_HEADER_TARBALL
  else
    if [ -e $CACHED_HEADER_TARBALL ]; then
      echo "Using cached N|Solid headers $VERSION_NSOLID/$VERSION_LTS" | output "$LOG_FILE"
    else
      echo "Downloading N|Solid headers $VERSION_NSOLID/$VERSION_LTS..." | output "$LOG_FILE"
      echo "url: $HEADER_URL" | output "$LOG_FILE"
      curl $HEADER_URL --silent --fail --retry 5 --retry-max-time 15 -o $CACHED_HEADER_TARBALL || (echo "Unable to download N|Solid $NSOLID_VERSION bundle; does it exist?" && false)
      echo "Downloaded [$HEADER_URL]" | output "$LOG_FILE"
    fi
  fi

  local NODEJS_VERSION=`$INSTALL_DIR/bin/nsolid -v | cut -c 2-`

  local HEADERS_DIR="$BUILD_DIR/.node-gyp/$NODEJS_VERSION"
  echo "Extracting headers `basename $CACHED_HEADER_TARBALL` to ~/.node-gyp/$NODEJS_VERSION" | output "$LOG_FILE"
  mkdir -p $HEADERS_DIR
  rm -rf $HEADERS_DIR/*
  tar xzf $CACHED_HEADER_TARBALL -C $HEADERS_DIR --strip-components 1
  echo 9 > $HEADERS_DIR/installVersion  # node-gyp magic version number
}
