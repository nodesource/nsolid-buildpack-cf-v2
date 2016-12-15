var semver = require('semver')

var requestedRange = process.argv[2]
var resolvedVersion

if (requestedRange === "") {
  resolvedVersion = "boron"
} else if (semver.satisfies("6.0.0", requestedRange)) {
  resolvedVersion = "boron"
} else if (semver.satisfies("4.0.0", requestedRange)) {
  resolvedVersion = "argon"
} else {
  resolvedVersion = "boron"
}

console.log(resolvedVersion)
