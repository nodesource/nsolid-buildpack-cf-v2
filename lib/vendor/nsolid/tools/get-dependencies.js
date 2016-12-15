'use strict'

// this script is designed to be run from /build-buildpack.zip.sh

const fs = require('fs')
const crypto = require('crypto')
const childProcess = require('child_process')

const semver = require('semver')

const DepsDir = 'dependencies'
const MetadataURL = 'https://nsolid-download.nodesource.com/download/metadata.json'
const MetadataFile = `${DepsDir}/metadata.json`

if (!fileExists(DepsDir)) {
  console.error(`the directory "${DepsDir}" does not exist`)
  process.exit(1)
}

download(MetadataURL, MetadataFile, processMetadata)

// process the metadata
function processMetadata (err, metadataFile) {
  if (err) process.exit(1)

  const metadataJSON = fs.readFileSync(metadataFile)
  const metadata = JSON.parse(metadataJSON)

  const nsolidVersions = Object.keys(metadata)
  nsolidVersions.sort(semver.rcompare)

  const nsolidVersion = nsolidVersions[0]
  const versionMetadata = metadata[nsolidVersion]

  const versions = {}
  const downloads = []
  let defaultVersion = '0.0.0'

  const nodeVersions = Object.keys(versionMetadata.versions)
  for (let nodeVersion of nodeVersions) {
    if (semver.gt(nodeVersion, defaultVersion)) defaultVersion = nodeVersion

    const nodeVersionMetadata = versionMetadata.versions[nodeVersion]
    const headersURL = nodeVersionMetadata.headersUrl
    // https://s3-us-west-2.amazonaws.com/nodesource-public-downloads/2.1.0/artifacts/headers/argon/v2.1.0/nsolid-v2.1.0-headers.tar.gz
    const match = headersURL.match(/\/artifacts\/headers\/(.*?)\/v/)
    const ltsVersion = match[1]
    const tarballURL = versionMetadata.artifacts.linux[`nsolid-${ltsVersion}`]
    const headersFile = `nsolid-headers-${nsolidVersion}-${ltsVersion}.tar.gz`
    const tarballFile = `nsolid-${nsolidVersion}-${ltsVersion}.tar.gz`

    versions[nodeVersion] = {
      nodeVersion: nodeVersion,
      nsolidVersion: nsolidVersion,
      ltsVersion: ltsVersion,
      headersURL: headersURL,
      tarballURL: tarballURL,
      headersFile: headersFile,
      tarballFile: tarballFile
    }

    downloads.push({ url: headersURL, file: `${DepsDir}/${headersFile}` })
    downloads.push({ url: tarballURL, file: `${DepsDir}/${tarballFile}` })
  }

  versions.defaultVersion = defaultVersion

  let count = downloads.length
  for (let download of downloads) {
    downloadIfNotExist(download.url, download.file, (err) => {
      if (err) return process.exit(1)
      count--
      if (count === 0) downloadsComplete(versions)
    })
  }
}

// downloads of dependencies done, write out dep info
function downloadsComplete (versions) {
  const defaultVersion = versions.defaultVersion
  delete versions.defaultVersion

  const versionList = Object.keys(versions)
  versionList.sort(semver.rcompare)

  const oldManifestLines = fs.readFileSync('manifest.yml', 'utf8').trim().split(/\n/g)
  const newManifestLines = []
  const dependencies = {
    defaultVersion: defaultVersion,
    versionList: versionList,
    versions: {}
  }

  for (let line of oldManifestLines) {
    newManifestLines.push(line)
    if (line === '# dependencies-start') break
  }

  newManifestLines.push('default_versions:')
  newManifestLines.push('- name: node')
  newManifestLines.push(`  version: ${defaultVersion}`)
  newManifestLines.push('- name: node-headers')
  newManifestLines.push(`  version: ${defaultVersion}`)
  newManifestLines.push('')
  newManifestLines.push('dependencies:')

  for (let nodeVersion of versionList) {
    const meta = versions[nodeVersion]
    const headersMD5 = md5(`${DepsDir}/${meta.headersFile}`)
    const tarballMD5 = md5(`${DepsDir}/${meta.tarballFile}`)

    const dependency = {
      ltsVersion: meta.ltsVersion,
      nodeVersion: nodeVersion,
      nsolidVersion: meta.nsolidVersion,
      tarballURL: meta.tarballURL,
      tarballFile: meta.tarballFile,
      headersURL: meta.headersURL,
      headersFile: meta.headersFile
    }

    dependencies.versions[nodeVersion] = dependency

    newManifestLines.push('- name: node')
    newManifestLines.push(`  lts: ${meta.ltsVersion}`)
    newManifestLines.push(`  nsolid: ${meta.nsolidVersion}`)
    newManifestLines.push(`  version: ${nodeVersion}`)
    newManifestLines.push(`  uri: ${meta.tarballURL}`)
    newManifestLines.push(`  md5: ${tarballMD5}`)
    newManifestLines.push(`  file: ${meta.tarballFile}`)
    newManifestLines.push('  cf_stacks:')
    newManifestLines.push('  - cflinuxfs2')

    newManifestLines.push('- name: node-headers')
    newManifestLines.push(`  lts: ${meta.ltsVersion}`)
    newManifestLines.push(`  nsolid: ${meta.nsolidVersion}`)
    newManifestLines.push(`  version: ${nodeVersion}`)
    newManifestLines.push(`  uri: ${meta.headersURL}`)
    newManifestLines.push(`  file: ${meta.headersFile}`)
    newManifestLines.push(`  md5: ${headersMD5}`)
    newManifestLines.push('  cf_stacks:')
    newManifestLines.push('  - cflinuxfs2')
  }

  let copying = false
  for (let line of oldManifestLines) {
    if (line === '# dependencies-end') copying = true
    if (copying) newManifestLines.push(line)
  }

  fs.writeFileSync('manifest.yml', newManifestLines.join('\n'))
  console.error('updated manifest.yml with version info')

  fs.writeFileSync('dependencies.json', JSON.stringify(dependencies, null, 2))
  console.error('updated dependencies.json with version info')
}

// return MD5 of file contents
function md5 (fileName) {
  const contents = fs.readFileSync(fileName)
  return crypto.createHash('md5').update(contents).digest('hex')
}

// download a file, via curl
function fileExists (fileName) {
  try {
    fs.accessSync(fileName)
    return true
  } catch (err) {
    return false
  }
}

// download a file if it doesn't already exist
function downloadIfNotExist (url, fileName, cb) {
  if (fileExists(fileName)) {
    console.error(`already downloaded: ${fileName}`)
    return setImmediate(cb, null, fileName)
  }
  download(url, fileName, cb)
}

// download a file, via curl
function download (url, fileName, cb) {
  console.error(`downloading: ${fileName}`)
  exec(`curl --output "${fileName}" ${url}`, execCB)

  function execCB (err) {
    if (err) {
      console.error(`error downloading: "${fileName}" from "${url}":`, err)
      return cb(err)
    }
    console.error(`downloaded:  ${fileName}`)
    cb(null, fileName)
  }
}

// run a command
function exec (cmd, cb) {
  childProcess.exec(cmd, (err, stdout, stderr) => {
    if (err) return cb(err)
    cb(null, stdout, stderr)
  })
}
