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

  local buildpackDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../.. && pwd )"
  local ltsVersionScript="$buildpackDir/bin/node lib/vendor/nsolid/tools/resolve-version.js"

  # ltsVersionScript writes bash commands out, that will be executed below
  local ltsVersion=`$buildpackDir/bin/node $ltsVersionScript "$requestedVersion" "$buildpackDir"`

  echo "N|Solid version $VERSION_NSOLID / $VERSION_LTS (equivalent Node.js version $VERSION_NODE)" | output "$LOG_FILE"

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
  mkdir -p $INSTALL_DIR
  mv /tmp/nsolid/* $INSTALL_DIR
  chmod +x $INSTALL_DIR/bin/*

  # N|Solid 2.1.0 argon linux did not ship a linked `node` ...
  if [[ ! -f "$INSTALL_DIR/bin/node" ]]; then
    cd "$INSTALL_DIR/bin"
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

  local HEADERS_DIR="$BUILD_DIR/.node-gyp/nsolid-$VERSION_NODE"
  echo "Extracting headers `basename $CACHED_HEADER_TARBALL` to ~/.node-gyp/nsolid-$VERSION_NODE" | output "$LOG_FILE"
  mkdir -p $HEADERS_DIR
  rm -rf $HEADERS_DIR/*
  tar xzf $CACHED_HEADER_TARBALL -C $HEADERS_DIR --strip-components 1
  echo 9 > $HEADERS_DIR/installVersion  # node-gyp magic version number
}
