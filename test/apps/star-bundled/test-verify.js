'use strict'

const utils = require('../../lib/utils')

exports.verify = verify

// verify the output of the test
function verify (t, results) {
  utils.checkVersions(t, results, 'carbon')
  utils.checkUUID(t, results)
  utils.checkBundled(t, results, true)
}
