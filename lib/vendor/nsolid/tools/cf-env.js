'use strict'

// Get CF-related environment variables.

exports.DefaultStorageServiceName = 'nsolid-storage'
exports.getVcapApplication = getVcapApplication
exports.getVcapServices = getVcapServices
exports.getStorageCredentials = getStorageCredentials

const path = require('path')

const Program = path.basename(__filename)
const DefaultStorageServiceName = exports.DefaultStorageServiceName

// These won't change for the lifetime of an app, so go ahead and cache
const VcapApplication = getJsonEnvVar('VCAP_APPLICATION')
const VcapServices = getJsonEnvVar('VCAP_SERVICES')

// Return env var VCAP_APPLICATION, parsed.
function getVcapApplication () {
  return JSON.parse(JSON.stringify(VcapApplication))
}

// Return env var VCAP_SERVICES, parsed.
function getVcapServices () {
  return JSON.parse(JSON.stringify(VcapServices))
}

function getStorageCredentials (storageServiceName) {
  if (storageServiceName == null) storageServiceName = DefaultStorageServiceName

  const result = getStorageServiceCredentials(storageServiceName)

  return JSON.parse(JSON.stringify(result))
}

// Get the storage service credentials from VCAP_SERVICES
function getStorageServiceCredentials (storageServiceName) {
  const upServices = VcapServices['user-provided']
  if (upServices == null) return null

  for (let service of upServices) {
    if (service.name === storageServiceName) return service.credentials
  }

  return null
}

// Return a JSON parsed env var (eg, VCAP_SERVICES etal)
function getJsonEnvVar (envVar) {
  const envVal = process.env[envVar]
  if (envVal == null) {
    error(`env var ${envVar} was unexpectedly not set, using {}`)
    return {}
  }

  try {
    return JSON.parse(envVal)
  } catch (err) {
    error(`env var ${envVar} was not valid JSON, using {}: ${envVal}`)
    return {}
  }
}

// Print an error message
function error (message) {
  console.error(`${Program}: ${message}`)
}
