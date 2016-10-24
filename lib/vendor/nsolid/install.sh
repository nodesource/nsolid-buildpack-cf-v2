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
  # incoming version parm is the Node.js version; eg, 6.9.1
  local NODE_VERSION="$1"
  local INSTALL_DIR="$2"
  local SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

  local JQ_EXPR_VERSION=".[\"v$NODE_VERSION\"]"
  local JQ_EXPR_VERSION_URL=".[\"v$NODE_VERSION\"][\"url\"]"
  local JQ_EXPR_VERSION_LTS=".[\"v$NODE_VERSION\"][\"lts\"]"
  local JQ_EXPR_VERSION_NSOLID=".[\"v$NODE_VERSION\"][\"nsolid\"]"

  # will be the URL to the appropriate tarball
  local VERSION_OBJECT=`$JQ --raw-output $JQ_EXPR_VERSION $SCRIPT_PATH/nsolid-versions.json`
  local VERSION_URL=`$JQ --raw-output $JQ_EXPR_VERSION_URL $SCRIPT_PATH/nsolid-versions.json`
  local VERSION_LTS=`$JQ --raw-output $JQ_EXPR_VERSION_LTS $SCRIPT_PATH/nsolid-versions.json`
  local VERSION_NSOLID=`$JQ --raw-output $JQ_EXPR_VERSION_NSOLID $SCRIPT_PATH/nsolid-versions.json`

  if [ "$VERSION_OBJECT" == "null" ];
  then
    error "unable to determine version of N|Solid for Node.js version $NODE_VERSION"
    exit 1
  fi

  if [ "$VERSION_URL" == "null" ];
  then
    error "nsolid-version.json error - url property not found for Node.js version $NODE_VERSION"
    exit 1
  fi

  if [ "$VERSION_LTS" == "null" ];
  then
    error "nsolid-version.json error - lts property not found for Node.js version $NODE_VERSION"
    exit 1
  fi

  if [ "$VERSION_NSOLID" == "null" ];
  then
    error "nsolid-version.json error - nsolid property not found for Node.js version $NODE_VERSION"
    exit 1
  fi

  echo "N|Solid version $VERSION_NSOLID/$VERSION_LTS, equiv Node.js version $NODE_VERSION" | output "$LOG_FILE"

  local CACHED_NSOLID_TARBALL="$CACHE_DIR/nsolid-$VERSION_NSOLID-$VERSION_LTS.tar.gz"
  mkdir -p $CACHE_DIR

  if [ -e $CACHED_NSOLID_TARBALL ]; then
    echo "Using cached N|Solid $VERSION_NSOLID/$VERSION_LTS" | output "$LOG_FILE"
  else
    echo "Downloading N|Solid $VERSION_NSOLID/$VERSION_LTS..." | output "$LOG_FILE"
    echo "url: $VERSION_URL" | output "$LOG_FILE"
    curl $VERSION_URL --silent --fail --retry 5 --retry-max-time 15 -o $CACHED_NSOLID_TARBALL || (echo "Unable to download N|Solid $NSOLID_VERSION bundle; does it exist?" && false)
    echo "Downloaded [$VERSION_URL]" | output "$LOG_FILE"
  fi

  echo "Extracting `basename $CACHED_NSOLID_TARBALL`" | output "$LOG_FILE"
  mkdir -p /tmp/nsolid/
  rm -rf /tmp/nsolid/*
  tar xzf $CACHED_NSOLID_TARBALL -C /tmp/nsolid --strip-components 1
  mkdir -p $INSTALL_DIR
  mv /tmp/nsolid/* $INSTALL_DIR
  chmod +x $INSTALL_DIR/bin/*
}
