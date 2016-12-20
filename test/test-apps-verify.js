#!/usr/bin/env node

'use strict'

const fs = require('fs')
const path = require('path')

const tape = require('tape')

const ProjectDir = path.dirname(__dirname)
const TestAppsDir = path.join(ProjectDir, 'test', 'apps')
const ResultsDir = path.join(ProjectDir, 'tmp', 'test', 'results')

let ResultDirs
try {
  ResultDirs = fs.readdirSync(ResultsDir)
} catch (err) {
  console.log(`no result dirs in "${ResultsDir}"`)
  process.exit(1)
}

for (let resultDir of ResultDirs) processResult(resultDir, path.join(ResultsDir, resultDir))

// run tests on result dir
function processResult (testApp, resultDir) {
  const verifyModuleName = path.join(TestAppsDir, testApp, 'test-verify')
  const pushTwice = fileExists(path.join(TestAppsDir, testApp, 'PUSH_TWICE'))

  tape(testApp, (t) => {
    // try loading the verify module
    let verifyModule
    try {
      verifyModule = require(verifyModuleName)
    } catch (err) {
      t.fail(`error loading verify module "${verifyModuleName}"`)
      console.log(err)
      t.end()
      return
    }

    // build the results
    let results = {
      curl: [ getJsonFile(t, resultDir, 'curl-1.json') ],
      push: [ getLinesFile(t, resultDir, 'push-1.txt') ],
      parms: getParmsFile(t, resultDir)
    }

    if (pushTwice) {
      results.curl.push(getJsonFile(t, resultDir, 'curl-2.json'))
      results.push.push(getLinesFile(t, resultDir, 'push-2.txt'))
    }

    // run the verify module with the results
    try {
      verifyModule.verify(t, results)
    } catch (err) {
      t.fail(`error running verify module "${verifyModuleName}"`)
      console.log(err)
      t.end()
      return
    }

    t.end()
  })
}

// get the contents of a file in the results
function getResultsFile (resultsDir, fileName) {
  try {
    return fs.readFileSync(path.join(resultsDir, fileName), 'utf8')
  } catch (err) {
    return undefined
  }
}

// get the contents of the parms file in the results
function getParmsFile (t, resultsDir) {
  const result = {}
  const lines = getLinesFile(t, resultsDir, 'parms.txt')

  for (let line of lines) {
    const match = line.match(/^(.*?):(.*)$/)
    if (match == null) continue

    const key = match[1].trim()
    const val = match[2].trim()
    result[key] = val
  }

  return result
}

// get the contents of a JSON file in the results
function getJsonFile (t, resultsDir, fileName) {
  const contents = getResultsFile(resultsDir, fileName)
  if (contents == null) {
    t.fail(`file "${resultsDir}/${fileName}" not found`)
    return {}
  }
  try {
    return JSON.parse(contents)
  } catch (err) {
    t.fail(`unable to parse file "${resultsDir}/${fileName}": ${err}`)
    return {}
  }
}

// get the contents of a lines file in the results
function getLinesFile (t, resultsDir, fileName) {
  const contents = getResultsFile(resultsDir, fileName)
  if (contents == null) {
    t.fail(`file "${resultsDir}/${fileName}" not found`)
    return []
  }

  return contents.trim().split(/\n/g)
}

function fileExists (fileName) {
  try {
    fs.accessSync(fileName)
    return true
  } catch (err) {
    return false
  }
}
