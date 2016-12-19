'use strict'

// Used by lib/vendor/nsolid/install.sh to get values of things for a
// resolved node version.
//
// Generates a set of bash commands that echo and set local variables.
//
// Still running with /bin/node, so ... use "old" node stuff only
//
// sets:
//   local VERSION_LTS= argon | boron | ...
//   local VERSION_NODE= node version
//   local VERSION_NSOLID= nsolid version
//
//   local NSOLID_URL= url to the N|Solid runtime tarball
//   local HEADER_URL= url to the N|Solid headers tarball
//
//   local NSOLID_TARBALL=        basename of the N|Solid runtime tarball
//   local BUNDLE_NSOLID_TARBALL= path to where dependency exists
//   local CACHED_NSOLID_TARBALL= path to where cached version may exist
//
//   local HEADER_TARBALL=        basename of the N|Solid headers tarball
//   local BUNDLE_HEADER_TARBALL= path to where dependency exists
//   local CACHED_HEADER_TARBALL= path to where cached version may exist
//
// Expects $PROJECT_PATH and $CACHE_DIR to already have been set.

var semver = require('semver')
var dependencies = require('../../../dependencies.json')

var output = []

var engineExpression = process.argv[2] || ''

// if no engine expression at all, use default
if (engineExpression === '') {
  output.push('echo "no engine version specified, using default"')
  engineExpression = dependencies.defaultVersion
}

// find highest dependencies that satisfies the engine expression
var resolvedVersion
for (var i = 0; i < dependencies.versionList.length; i++) {
  var testVersion = dependencies.versionList[i]
  if (semver.satisfies(testVersion, engineExpression)) {
    resolvedVersion = testVersion
    break
  }
}

if (resolvedVersion == null) {
  output.push('echo "unable to match engine expression \"' + engineExpression + '\"; using default"')
  resolvedVersion = dependencies.defaultVersion
}

var versionData = dependencies.versions[resolvedVersion]
var variables = {}

variables.VERSION_LTS=versionData.ltsVersion
variables.VERSION_NODE=versionData.nodeVersion
variables.VERSION_NSOLID=versionData.nsolidVersion

variables.NSOLID_URL=versionData.tarballURL
variables.HEADER_URL=versionData.headersURL

variables.NSOLID_TARBALL=versionData.tarballFile
variables.BUNDLE_NSOLID_TARBALL="$PROJECT_PATH/dependencies/$NSOLID_TARBALL"
variables.CACHED_NSOLID_TARBALL="$CACHE_DIR/$NSOLID_TARBALL"

variables.HEADER_TARBALL=versionData.headersFile
variables.BUNDLE_HEADER_TARBALL="$PROJECT_PATH/dependencies/$HEADER_TARBALL"
variables.CACHED_HEADER_TARBALL="$CACHE_DIR/$HEADER_TARBALL"

for (var varName in variables) {
  var value = variables[varName]
  output.push('local ' + varName + '="' + value + '"')
}

// write the bash commands
console.log(output.join(';'))
