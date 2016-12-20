'use strict'

exports.matchPushLine = matchPushLine
exports.checkVersions = checkVersions
exports.checkUUID = checkUUID
exports.checkBundled = checkBundled

// return match if regexp matches a line in the results push array, else false
function matchPushLine (results, index, regexp) {
  const lines = results.push[index]
  for (let line of lines) {
    const match = line.match(regexp)
    if (match) return match
  }

  return false
}

// check using the bundled vs unbundled version
function checkBundled (t, results, isBundled) {
  const pattern = isBundled ? /Using bundled N\|Solid/ : /Downloading N\|Solid/

  for (let i = 0; i < results.push.length; i++) {
    t.ok(matchPushLine(results, i, pattern), `found output "${pattern}"`)
  }
}

// check that the UUID in parms is the same as the one in curl
function checkUUID (t, results) {
  const expectedUUID = results.parms.uuid

  for (let i = 0; i < results.curl.length; i++) {
    t.equal(results.curl[i].uuid, expectedUUID, `UUID parm matched curl result [${i}]`)
  }
}

// check that the versions in parms are reflected in the results
function checkVersions (t, results, ltsVersion) {
  const buildpackVersion = results.parms.buildpackVersion
  const nsolidVersion = results.parms.nsolidVersion

  const nsolidRegExp = /N\|Solid version (.*?) \/ (.*?) \(equivalent Node\.js version (.*?)\)/
  const buildpackRegExp = /-------> Buildpack version (.*)/

  t.ok(results.push.length > 0, 'results.pushLines has lines')

  let match

  for (let i = 0; i < results.push.length; i++) {
    match = matchPushLine(results, i, nsolidRegExp)
    t.ok(match, `matched nsolid version line in results.pushLines[${i}]`)
    if (match) {
      t.equal(match[1], nsolidVersion, `nsolid versions should match (${nsolidVersion})`)
      t.equal(match[2], ltsVersion, `lts versions should match (${ltsVersion})`)
      // TODO: add test for node.js version, once we have it
    }

    match = matchPushLine(results, i, buildpackRegExp)
    t.ok(match, `matched buildpack version line in results.pushLines[${i}]`)
    if (match) {
      t.equal(match[1], buildpackVersion, `buildpack versions should match (${buildpackVersion})`)
    }
  }
}
