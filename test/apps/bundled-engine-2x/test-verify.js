'use strict'

exports.verify = verify

// verify the output of the test
function verify (fileMap) {
  const uuid = fileMap['uuid.txt'].trim()
  const pushLines = fileMap['push.out.txt'].trim().split("\n")
  const curlOut = JSON.parse(fileMap['curl.out.txt'])
}
