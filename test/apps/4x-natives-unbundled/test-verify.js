'use strict'

const utils = require('../../lib/utils')

exports.verify = verify

// verify the output of the test
function verify (t, results) {
  utils.checkVersions(t, results, 'argon')
  utils.checkUUID(t, results)
  utils.checkBundled(t, results, false)

  t.equal(results.curl[0].buff, 'buffer', 'buff property has expected value')
}
