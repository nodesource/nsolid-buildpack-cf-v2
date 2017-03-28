'use strict'

// this script is designed to be run directly from the cli or bash

var semver = require('semver');

var requestedRange = process.argv[2];
var manifestVersionsJson = process.argv[3];
var defaultVersion = process.argv[4];
var resolvedVersion;

var manifestVersions = JSON.parse(manifestVersionsJson);
manifestVersions = manifestVersions.sort(semver.compare).reverse();

if (requestedRange === "") {
  console.log(defaultVersion);
  return;
}

for (var i = 0; i <= manifestVersions.length; i++) {
  var manifestVersion = manifestVersions[i]
  var match;
  try {
    match = semver.satisfies(manifestVersion, requestedRange);
  } catch (err) {
    match = false;
  }

  if (match) {
    console.log(manifestVersion);
    return
  }
}

console.log(defaultVersion);
