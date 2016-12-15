'use strict'

// Used by lib/vendor/nsolid/install.sh to get values of things for a
// resolved node version.

// Still running with /bin/node, so ... use "old" node stuff only

var semver = require('semver')
var dependencies = require('../../../../dependencies.json')

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
  output.push('echo "unable to match engine expression \'' + engineExpression + '\'; using default"')
  resolvedVersion = dependencies.defaultVersion
}

var versionData = dependencies.versions[resolvedVersion]
var variables = {
  VERSION_LTS: versionData.ltsVersion,
  VERSION_NODE: resolvedVersion,
  VERSION_NSOLID: versionData.nsolidVersion,
  NSOLID_URL: versionData.tarballURL,
  HEADER_URL: versionData.headersURL,
  NSOLID_TARBALL: versionData.tarballFile,
  HEADER_TARBALL: versionData.headersFile
}

for (var key in variables) {
  output.push('local ' + key + '="' + variables[key] + '"')
}

console.log(output.join(';'))
