'use strict'

// Run tunnels for zmq from agent to storage

const path = require('path')
const childProcess = require('child_process')

const cfEnv = require('./cf-env')

const Program = path.basename(__filename)

const StorageServiceName = cfEnv.DefaultStorageServiceName
const VcapApplication = cfEnv.getVcapApplication()

log('determining tunnels that should be set up')

// extract some values
const VcapAppName = VcapApplication.application_name
const VcapSpaceName = VcapApplication.space_name

if (VcapAppName == null) {
  error('expecting VCAP_APPLICATION to have application_name property')
  error('tunnels will not be set up')
  process.exit(1)
}

if (VcapSpaceName == null) {
  error('expecting VCAP_APPLICATION to have space_name property')
  error('tunnels will not be set up')
  process.exit(1)
}

// get the storage credentials
const storageCredentials = cfEnv.getStorageCredentials(StorageServiceName)
if (storageCredentials == null) {
  error(`expecting a bound user-provided service named ${StorageServiceName}`)
  error('tunnels will not be set up')
  process.exit(1)
}

// check the tunnel type, if any
if (storageCredentials.tunnel === 'cf-ssh') {
  runTunnelCfSsh(storageCredentials)
} else {
  log('no "tunnel" property, not using tunnels')
  process.exit(0)
}

// run the cf ssh tunnel
function runTunnelCfSsh (storageCredentials) {
  // get the storageApp property
  const storageApp = storageCredentials['storageApp']
  if (storageApp == null) {
    error(`expecting storage service ${StorageServiceName} to have property storageApp`)
    process.exit(1)
  }

  // check credentials for all required properties
  const requiredKeys = 'user password cfapi org space app'.split(' ')
  let someMissing = false
  for (let requiredKey of requiredKeys) {
    if (storageApp[requiredKey] == null) {
      someMissing = true
      error(`expecting storage service ${StorageServiceName} to have property ${requiredKey}`)
    }
  }

  if (someMissing) {
    error('tunnels cannot be set up')
    process.exit(1)
  }

  // check to see if target of the tunnel is ourself!
  if (VcapAppName === storageApp.app && VcapSpaceName === storageApp.space) {
    log('looks like the app would be tunnelling to itself')
    log('tunnels will not be set up')
    process.exit(0)
  }

  loginAndTunnel(storageCredentials)
}

function loginAndTunnel (storageCredentials) {
  login(storageCredentials, onLogin)

  function onLogin (err) {
    if (err) {
      error(`error logging in: ${err.message}`)
      error('tunnels cannot be set up')
      process.exit(1)
    }

    log('logged into cf')

    // start those tunnels!
    startTunnels(storageCredentials, [9001, 9002, 9003], onStartTunnels)
  }

  function onStartTunnels (err) {
    if (err) {
      error(`error running tunnels: ${err.message}`)
    } else {
      error('tunneller stopped for unknown reason')
    }

    error('restarting in a few seconds')

    setTimeout(() => loginAndTunnel(storageCredentials), 5000)
  }
}

// Log into specified CF installation.
function login (storageCredentials, cb) {
  // cf login --skip-ssl-validation -a https://api.local.pcfdev.io -o pcfdev-org -s pcfdev-space -u user -p pass
  const storageApp = storageCredentials['storageApp']

  log('logging into cf')

  const args = [
    'login', '--skip-ssl-validation',
    '-a', storageApp.cfapi,
    '-o', storageApp.org,
    '-s', storageApp.space,
    '-u', storageApp.user,
    '-p', storageApp.password
  ]

  const opts = {
    stdio: 'inherit'
  }

  runCommand('.nsolid-bin/cf', args, opts, (err, code, signal) => {
    if (err) return cb(err)
    if (signal) return cb(new Error(`signal received: ${signal}`))
    if (code !== 0) return cb(new Error(`process returned ${code}`))

    cb(null)
  })
}

// Start new tunnels to specified app, on specified ports
function startTunnels (storageCredentials, ports, cb) {
  // cf ssh nsolid-storage -T -L 9001:localhost:9001 -L 9002:localhost:9002 -L 9003:localhost:9003
  const storageApp = storageCredentials['storageApp']

  log('starting tunnels')

  const args = [
    'ssh', storageApp.app,
    '--disable-pseudo-tty',
    '--skip-host-validation',
    '--skip-remote-execution'
  ]

  for (let port of ports) {
    args.push('-L')
    args.push(`${port}:localhost:${port}`)
  }

  const opts = {
    stdio: 'ignore'
  }

  runCommand('.nsolid-bin/cf', args, opts, (err, code, signal) => {
    if (err) return cb(err)
    if (signal) return cb(new Error(`signal received: ${signal}`))
    if (code !== 0) return cb(new Error(`process returned ${code}`))

    cb(null)
  })
}

// Run a command.
function runCommand (cmd, args, opts, cb) {
  // const cmdPrint = `${cmd} ${args.join(' ')}`
  // log(`running command: ${cmdPrint}`)

  const process = childProcess.spawn(cmd, args, opts)

  process.on('exit', (code, signal) => {
    if (cb == null) return
    cb(null, code, signal)
    cb = null
  })

  process.on('error', (err) => {
    if (cb == null) return
    cb(err)
    cb = null
  })
}

// Print a message to stdout
function log (message) {
  console.log(`${Program}: ${message}`)
}

// Print a message to stderr
function error (message) {
  console.error(`${Program}: ${message}`)
}
