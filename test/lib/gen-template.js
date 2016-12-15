'use strict'

const fs = require('fs')

const tmpFile = process.argv[2]
const outFile = process.argv[3]
const replacements = []

if (process.argv.length % 2 !== 0) {
  console.log('you forgot a replacement value ...')
  process.exit(1)
}

for (let i = 4; i < process.argv.length ; i += 2) {
  replacements.push([process.argv[i], process.argv[i+1]])
}

const tmpContents = fs.readFileSync(tmpFile, 'utf8')
let outContents = tmpContents

replacements.forEach((pair) => {
  const oldString = new RegExp(`%${pair[0]}%`, 'g')
  const newString = pair[1]
  outContents = outContents.replace(oldString, newString)
})

fs.writeFileSync(outFile, outContents)
