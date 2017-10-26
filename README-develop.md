N|Solid Cloud Foundry Buildpack - development info
================================================================================

Because the buildpack is typically referenced via a URL to the git repo, every
commit to this repo, that isn't just documentation, should use a new version.
That means:

* increment the `VERSION` file
* add a git tag, with a `v` prefix, eg `v1.0.0`

Additionally:

* every release should test using all LTS releases; eg, argon, boron, carbon

* VERSION.cf-nodejs-buildpack is the version of the Node.js buildpack this
  was based on; when updating content based on Cloud Foundry Node.js
  buildpack changes, update this file.


Cutting a new release
================================================================================

Updates needed for every release - in theory, only source changes required:

* update the `VERSION` file to the version number of the buildpack
* update the `VERSION.nsolid` file to the version number of N|Solid
* update the `CHANGELOG.md` file

To rebuild/test the buildpacks in context of those changes:

* run `lib/vendor/nsolid/tools/build-buildpack-zip.sh` to build the buildpack
  archives
* run `test/test-apps-run.sh` to run tests against those buildpacks
  * note the tests run against a local, default install of [PCFdev][]
* run `test/test-apps-verify.js` to verify the results of those tests

[PCFdev]: https://github.com/pivotal-cf/pcfdev

When everything's ready to go:

* merge to master
* tag commit with version number
* upload bundled and unbundled zipped buildpacks to [GH release page][]

[GH release page]: https://github.com/nodesource/nsolid-buildpack-cf/releases


Differences from the Cloud Foundry Buildpack for Node.js
================================================================================

The Cloud Foundry Buildpack for Node.js is avaliable here:

<https://github.com/cloudfoundry/nodejs-buildpack>

The differences between the N|Solid buildpack and the Node.js buildpack, as of
version 1.5.22, are:

- added nsolid entry to `.gitignore`
- replaced the `CHANGELOG.md`
- added `CODE_OF_CONDUCT.md`
- removed `CONTRIBUTING.md` (some content now in `README.md`)
- removed `ISSUE_TEMPLATE`
- renamed `LICENSE` to `LICENSE.md`, embeds Node.js buildpack license, N|Solid is at top
- modified `manifest.yml` to only include Node.js versions corresponding to the N|Solid releases
- removed `PULL_REQUEST_TEMPLATE`
- copied original `README.md` to `README-cf-nodejs-buildpack.md`
- added new `README.md`
- renamed original `VERSION` to `VERSION.cf-nodejs-buildpack`
- changed `VERSION` to restart at `1.0.0`
- one line modification to `bin/compile`, to add nsolid bits
- one line mod to `lib/binaries.sh`, to add nsolid bits
- everything in `lib/vendor/nsolid` is new
