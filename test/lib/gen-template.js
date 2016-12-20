'use strict'

const fs = require('fs')

const tmpFile = process.argv[2]
const outFile = process.argv[3]

if (process.argv.length % 2 !== 0) {
  console.log('replacement key provided without replacement value')
  process.exit(1)
}

let outContents
try {
  outContents = fs.readFileSync(tmpFile, 'utf8')
} catch (err) {
  // file doesn't exist, just exit
  process.exit(0)
}

for (let i = 4; i < process.argv.length; i += 2) {
  const oldString = new RegExp(`%${process.argv[i]}%`, 'g')
  const newString = process.argv[i + 1]
  outContents = outContents.replace(oldString, newString)
}

try {
  console.log(`generating file "${outFile}" from template "${tmpFile}"`)
  fs.writeFileSync(outFile, outContents)
} catch (err) {
  console.log(`unable to write file "${outFile}: ${err}`)
  process.exit(1)
}
