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
  cp $SCRIPT_PATH/bins/profile.d.nsolid.sh $BUILD_DIR/.profile.d/nsolid.sh
}

init_nsolid $1

# override of /lib/binaries.sh::install_nodejs()
install_nodejs() {
  local requestedVersion="$1"
  local installNodeDir="$2"
  local installDir="$3"

  local projectPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../.. && pwd )"

  # sets the following local vars:
  #   local VERSION_LTS="boron"
  #   local VERSION_NODE="6.9.2"
  #   local VERSION_NSOLID="2.1.0"
  #   local NSOLID_URL="https:..."
  #   local HEADER_URL="https:..."
  #   local NSOLID_TARBALL="nsolid-2.1.0-boron.tar.gz"
  #   local HEADER_TARBALL="nsolid-headers-2.1.0-boron.tar.gz"

  eval `$projectPath/bin/node $projectPath/lib/vendor/nsolid/tools/resolve-version.js "$1"`

  echo "N|Solid version $VERSION_NSOLID / $VERSION_LTS (equivalent Node.js version $VERSION_NODE)" | output "$LOG_FILE"

  local BUNDLE_NSOLID_TARBALL="$projectPath/dependencies/$NSOLID_TARBALL"
  local CACHED_NSOLID_TARBALL="$CACHE_DIR/$NSOLID_TARBALL"

  local BUNDLE_HEADER_TARBALL="$projectPath/dependencies/$HEADER_TARBALL"
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
      curl $NSOLID_URL --silent --fail --retry 5 --retry-max-time 15 -o $CACHED_NSOLID_TARBALL || (echo "Unable to download N|Solid $NSOLID_VERSION bundle; does it exist?" && false)
    fi
  fi

  echo "Extracting `basename $CACHED_NSOLID_TARBALL`" | output "$LOG_FILE"
  mkdir -p /tmp/nsolid/
  rm -rf /tmp/nsolid/*
  tar xzf $CACHED_NSOLID_TARBALL -C /tmp/nsolid --strip-components 1
  mkdir -p $installNodeDir
  mv /tmp/nsolid/* $installNodeDir
  chmod +x $installNodeDir/bin/*

  # N|Solid 2.1.0 argon linux did not ship a linked `node` ...
  if [[ ! -f "$installNodeDir/bin/node" ]]; then
    cd "$installNodeDir/bin"
    ln -s "./nsolid" "node"
  fi

  if [ -e $BUNDLE_HEADER_TARBALL ]; then
    echo "Using bundled N|Solid headers $VERSION_NSOLID/$VERSION_LTS" | output "$LOG_FILE"
    cp $BUNDLE_HEADER_TARBALL $CACHED_HEADER_TARBALL
  else
    if [ -e $CACHED_HEADER_TARBALL ]; then
      echo "Using cached N|Solid headers $VERSION_NSOLID/$VERSION_LTS" | output "$LOG_FILE"
    else
      echo "Downloading N|Solid headers $VERSION_NSOLID/$VERSION_LTS..." | output "$LOG_FILE"
      curl $HEADER_URL --silent --fail --retry 5 --retry-max-time 15 -o $CACHED_HEADER_TARBALL || (echo "Unable to download N|Solid $NSOLID_VERSION bundle; does it exist?" && false)
    fi
  fi

  local HEADERS_DIR="$installDir/.node-gyp/nsolid-$VERSION_NODE"
  echo "Extracting headers `basename $CACHED_HEADER_TARBALL` to ~/.node-gyp/nsolid-$VERSION_NODE" | output "$LOG_FILE"
  mkdir -p $HEADERS_DIR
  rm -rf $HEADERS_DIR/*
  tar xzf $CACHED_HEADER_TARBALL -C $HEADERS_DIR --strip-components 1
  echo 9 > $HEADERS_DIR/installVersion  # node-gyp magic version number
}
