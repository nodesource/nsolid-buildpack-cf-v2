'use strict'

/* eslint-disable camelcase */

// Returns the value of a computed N|Solid env var for agents, suitable for use
// as follows:
//
//    export NSOLID_APPNAME=`node compute-env-value.js NSOLID_APPNAME`

// used by the nsolid.sh script installed in .profile.d

const path = require('path')

const cfEnv = require('./cf-env')

const Program = path.basename(__filename)

const StorageServiceName = cfEnv.DefaultStorageServiceName

// Write the computed value of an N|Solid env var, from the CF env

// env var names that can be passed in
const VarFns = {
  NSOLID_APPNAME: get_NSOLID_APPNAME,
  NSOLID_TAGS: get_NSOLID_TAGS,
  NSOLID_COMMAND_REMOTE: get_NSOLID_COMMAND_REMOTE,
  NSOLID_DATA_REMOTE: get_NSOLID_DATA_REMOTE,
  NSOLID_BULK_REMOTE: get_NSOLID_BULK_REMOTE,
  NSOLID_STORAGE_PUBKEY: get_NSOLID_STORAGE_PUBKEY
}

// get VCAP env vars as JSON value
const VcapApplication = cfEnv.getVcapApplication()

// get credentials for user-provided service for storage
const StorageCredentials = cfEnv.getStorageCredentials(StorageServiceName)
if (StorageCredentials == null) {
  error(`expecting a bound user-provided service named ${StorageServiceName}`)
  process.exit(1)
}

const Tunnel = StorageCredentials.tunnel

const StorageApp = (Tunnel === 'cf-ssh')
  ? StorageCredentials['storageApp']
  : null

const Sockets = (Tunnel == null)
  ? StorageCredentials['sockets']
  : null

if (StorageApp == null && Sockets == null) {
  error(`the user-provided service named ${StorageServiceName} is invalid`)
  process.exit(1)
}

// process requested env var name
const envVar = process.argv[2]
if (envVar == null) {
  error('expecting an N|Solid env var name as a parameter')
  process.exit(1)
}

// if the env var is already set, use that, except for NSOLID_TAGS
const envVal = process.env[envVar]
if (envVal != null && envVar !== 'NSOLID_TAGS') {
  console.log(envVal)
  process.exit(0)
}

// get the function to calculate the value
const getFn = VarFns[envVar]
if (getFn == null) {
  error(`N|Solid env var ${envVar} not supported`)
  process.exit(1)
}

// calculate the value, write to stdout
const calculatedVal = getFn(envVar, envVal)
if (calculatedVal == null) process.exit(0)

console.log(calculatedVal)
process.exit(0)

// Return an appropriate NSOLID_APPNAME value
function get_NSOLID_APPNAME (envVar, envVal) {
  let val

  val = VcapApplication.application_name
  if (val != null) return val

  val = VcapApplication.name
  if (val != null) return val
}

// Return an appropriate NSOLID_TAGS value
function get_NSOLID_TAGS (envVar, envVal) {
  const tags = []

  // pull some values from the VCAP env vars
  const cfAppId = VcapApplication.application_id
  const cfAppVersion = VcapApplication.application_version
  const cfSpace = VcapApplication.space_name

  // convert to NSOLID_TAGS values
  if (cfAppId != null) tags.push(`cfAppId:${cfAppId}`)
  if (cfAppVersion != null) tags.push(`cfAppVersion:${cfAppVersion}`)
  if (cfSpace != null) tags.push(`cfSpace:${cfSpace}`)

  // build the string of tags
  const tagsVal = tags.join(',')

  // return string of tags, or append to existing value
  if (envVal == null) return tagsVal
  return `${envVal},${tagsVal}`
}

// Return an appropriate NSOLID_COMMAND_REMOTE value
function get_NSOLID_COMMAND_REMOTE (envVar, envVal) {
  if (Sockets != null) return Sockets.command

  return 'localhost:9001'
}

// Return an appropriate NSOLID_DATA_REMOTE value
function get_NSOLID_DATA_REMOTE (envVar, envVal) {
  if (Sockets != null) return Sockets.data

  return 'localhost:9002'
}

// Return an appropriate NSOLID_BULK_REMOTE value
function get_NSOLID_BULK_REMOTE (envVar, envVal) {
  if (Sockets != null) return Sockets.bulk

  return 'localhost:9003'
}

// Return an appropriate NSOLID_STORAGE_PUBKEY value
function get_NSOLID_STORAGE_PUBKEY (envVar, envVal) {
  if (StorageCredentials.publicKey == null) return
  return StorageCredentials.publicKey
}

// Print a message to stderr
function error (message) {
  console.error(`${Program}: ${message}`)
}
