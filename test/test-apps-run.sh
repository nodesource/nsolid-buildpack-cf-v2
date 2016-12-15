#!/usr/bin/env bash

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
TEST_WRK_DIR="$PROJECT_DIR/tmp/test"
TEST_SRC_DIR="$PROJECT_DIR/test"
BUILDPACK_VERSION=`cat $PROJECT_DIR/VERSION`

BUILDPACK_U=test_nsolid_buildpack
BUILDPACK_B=test_nsolid_buildpack_bundled

BUILDPACK_UZIP="$PROJECT_DIR/buildpacks/nsolid_buildpack-v${BUILDPACK_VERSION}.zip"
BUILDPACK_BZIP="$PROJECT_DIR/buildpacks/nsolid_buildpack-bundled-v${BUILDPACK_VERSION}.zip"

# main processing
function main() {
  cd "$PROJECT_DIR"
  rm -rf "$TEST_WRK_DIR"

  echo "restarting cf dev"
  cf dev suspend
  cf dev resume

  installBuildPacks

  # run npm install on the app
  cd "$TEST_SRC_DIR/app"
  rm -rf node_modules
  npm install
  cd "$PROJECT_DIR"

  runTestApp "unbundled-engine-none" $BUILDPACK_U
  #unTestApp "unbundled-engine-2x"   $BUILDPACK_U 2.x
  runTestApp "unbundled-engine-4x"   $BUILDPACK_U 4.x
  #unTestApp "unbundled-engine-6x"   $BUILDPACK_U 6.x
  #unTestApp "unbundled-engine-8x"   $BUILDPACK_U 8.x

  runTestApp "bundled-engine-none"   $BUILDPACK_B
  runTestApp "bundled-engine-2x"     $BUILDPACK_B 2.x
  runTestApp "bundled-engine-4x"     $BUILDPACK_B 4.x
  runTestApp "bundled-engine-6x"     $BUILDPACK_B 6.x
  runTestApp "bundled-engine-8x"     $BUILDPACK_B 8.x
}

# run a test
function runTestApp() {
  local testName=$1
  local buildPack=$2
  local engine=$3
  local uuid=`uuidgen`

  echo ""
  echo "-----------------------------------------------------------------------"
  echo "running $testName"
  echo "-----------------------------------------------------------------------"

  local resultsDir="$TEST_WRK_DIR/results/$testName"
  mkdir -p "$resultsDir"

  echo "$buildPack" "$uuid" "$engine" > "$resultsDir/parms.txt"

  rm -rf   "$TEST_WRK_DIR/app"
  mkdir -p "$TEST_WRK_DIR/app"
  cp -R "$TEST_SRC_DIR"/app/* "$TEST_WRK_DIR/app"

  node "$TEST_SRC_DIR/lib/gen-template" \
    "$TEST_WRK_DIR/app/manifest-TEMPLATE.yml" \
    "$TEST_WRK_DIR/app/manifest.yml" \
    BUILDPACK     $buildPack \
    UUID          $uuid \
    NODE_ENGINE   "$engine"

  node "$TEST_SRC_DIR/lib/gen-template" \
    "$TEST_WRK_DIR/app/Procfile-TEMPLATE" \
    "$TEST_WRK_DIR/app/Procfile" \
    BUILDPACK     $buildPack \
    UUID          $uuid \
    NODE_ENGINE   "$engine"

  if ! [ -z "$engine" ]; then
    node "$TEST_SRC_DIR/lib/gen-template" \
      "$TEST_WRK_DIR/app/package-engine-TEMPLATE.json" \
      "$TEST_WRK_DIR/app/package.json" \
      BUILDPACK     $buildPack \
      UUID          $uuid \
      NODE_ENGINE   "$engine"
  fi

  cd "$TEST_WRK_DIR/app"

  cf delete test-buildpack -f

  echo "pushing app ..."
  cf push > "$resultsDir/push.out.txt"

  echo "curling app ..."
  curl http://test-buildpack.local.pcfdev.io/ > "$resultsDir/curl.out.txt"

  cf delete test-buildpack -f

  cd "$PROJECT_DIR"
}

# install the buildpacks
function installBuildPacks() {
  # login as admin
  cf login -u admin -p admin -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation

  # delete old buildpacks
  cf delete-buildpack $BUILDPACK_U -f
  cf delete-buildpack $BUILDPACK_B -f

  # add new buildpacks
  cf create-buildpack $BUILDPACK_U "$BUILDPACK_UZIP" 1000
  cf create-buildpack $BUILDPACK_B "$BUILDPACK_BZIP" 1000

  #login as user
  cf login -u user  -p pass  -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation
}

# run main
main
