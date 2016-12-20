#!/usr/bin/env bash

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
TEST_WRK_DIR="$PROJECT_DIR/tmp/test"
TEST_SRC_DIR="$PROJECT_DIR/test"
BUILDPACK_VERSION=`cat $PROJECT_DIR/VERSION`
NSOLID_VERSION=`cat $PROJECT_DIR/VERSION.nsolid`

BUILDPACK_U=test_nsolid_buildpack
BUILDPACK_B=test_nsolid_buildpack_bundled

BUILDPACK_UZIP="$PROJECT_DIR/nsolid_buildpack-v${BUILDPACK_VERSION}.zip"
BUILDPACK_BZIP="$PROJECT_DIR/nsolid_buildpack-bundled-v${BUILDPACK_VERSION}.zip"

if [[ ! -f $BUILDPACK_UZIP ]]; then
  echo "file '$BUILDPACK_UZIP' not found, exiting"
  exit 1
fi

if [[ ! -f $BUILDPACK_BZIP ]]; then
  echo "file '$BUILDPACK_BZIP' not found, exiting"
  exit 1
fi

# main processing
function main() {
  local oneTest=$1
  local oneTestDir="$PROJECT_DIR/test/apps/${oneTest}"

  cd "$PROJECT_DIR"

  # echo "restarting cf dev"
  # cf dev suspend
  # cf dev resume

  # if a single test app is requested:
  # * only run that test app
  # * don't remove previous results
  if [[ ! -z "$oneTest" ]]; then
    if [[ ! -d "$oneTestDir" ]]; then
      echo "Can't find test dir ${oneTestDir}"
      exit 1
    fi
  else
    rm -rf "$TEST_WRK_DIR"
  fi

  echo ""
  echo "-----------------------------------------------------------------------"
  echo "installing buildpacks"
  echo "-----------------------------------------------------------------------"

  cf login -u admin -p admin -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation
  installBuildPacks
  cf login -u user  -p pass  -o pcfdev-org -a https://api.local.pcfdev.io --skip-ssl-validation

  # run the single tests or all the tests
  if [[ ! -z "$oneTest" ]]; then
    runTest ${oneTestDir}
  else
    # loop over apps
    for testDir in test/apps/*; do
      # testDir = test/apps/...
      if [[ ! -d ${testDir} ]]; then continue; fi

      local baseTestDir=`basename "${testDir}"`
      local absTestDir="$PROJECT_DIR/test/apps/${baseTestDir}"
      runTest "$absTestDir"
    done
  fi

  cd "$PROJECT_DIR"
}

function runTest() {
  local absTestDir=$1

  local testName=`basename "$absTestDir"`
  local uuid=`uuidgen`
  local resultsDir="$TEST_WRK_DIR/results/$testName"

  echo ""
  echo "-----------------------------------------------------------------------"
  echo "running $testName"
  echo "-----------------------------------------------------------------------"

  cd "$absTestDir"

  mkdir -p "$resultsDir"

  rm -rf "$resultsDir/parms.txt"
  echo "uuid:             $uuid"              >> "$resultsDir/parms.txt"
  echo "buildpackVersion: $BUILDPACK_VERSION" >> "$resultsDir/parms.txt"
  echo "nsolidVersion:    $NSOLID_VERSION"    >> "$resultsDir/parms.txt"

  node "$TEST_SRC_DIR/lib/gen-template" \
    "manifest-TEMPLATE.yml" \
    "manifest.yml" \
    UUID $uuid
  if [[ "$?" -ne "0" ]]; then exit 1; fi

  node "$TEST_SRC_DIR/lib/gen-template" \
    "Procfile-TEMPLATE" \
    "Procfile" \
    UUID $uuid
  if [[ "$?" -ne "0" ]]; then exit 1; fi

  node "$TEST_SRC_DIR/lib/gen-template" \
    "package-TEMPLATE.json" \
    "package.json" \
    UUID $uuid
  if [[ "$?" -ne "0" ]]; then exit 1; fi

  if [[ -f BEFORE-TEST.sh ]]; then
    echo "running BEFORE-TEST.sh"
    bash BEFORE-TEST.sh
  fi

  cf delete test-buildpack -f

  echo "pushing app 1st time ..."
  cf push > "$resultsDir/push-1.txt"

  echo "curling app 1st time..."
  curl http://test-buildpack.local.pcfdev.io/ > "$resultsDir/curl-1.json"

  if [[ -e PUSH-TWICE ]]; then
    echo "pushing app 2nd time ..."
    cf push > "$resultsDir/push-2.txt"

    echo "curling app 2nd time..."
    curl http://test-buildpack.local.pcfdev.io/ > "$resultsDir/curl-2.json"
  fi

  cd "$PROJECT_DIR"
}

# install the buildpacks
function installBuildPacks() {
  # delete old buildpacks
  cf delete-buildpack $BUILDPACK_U -f
  cf delete-buildpack $BUILDPACK_B -f

  # add new buildpacks
  cf create-buildpack $BUILDPACK_U "$BUILDPACK_UZIP" 1000
  cf create-buildpack $BUILDPACK_B "$BUILDPACK_BZIP" 1000
}

# run main
main $*
