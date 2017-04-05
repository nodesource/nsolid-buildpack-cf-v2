v1.0.7 2017-04-05
================================================================================

* updated to N|Solid 2.1.4

v1.0.6 2017-03-28
================================================================================

* updated to N|Solid 2.1.3
* fixed version resolver so that only engines/node ranges that match 4.x will
  return 4.x, others will return 6.x; previously used version of that rule
  where 4.x and 6.x were switched
* added tests for package.json files with no and "*" engines/node values

v1.0.5 2017-02-03
================================================================================

* updated to N|Solid 2.1.2
* deleted `lib/vendor/nsolid/nsolid-versions.json` since it's no longer
  needed and thus confusing to have around

v1.0.4 2017-01-18
================================================================================

* updated to N|Solid 2.1.1
* changed `lib/vendor/nsolid/tools/build-buildpack-zip.sh` to exit early if
  requested runtime binary is not available

v1.0.3 2016-12-19
================================================================================

* Updated to N|Solid 2.1.0
* Add symlink of `node` to `nsolid` if doesn't exist
* Change `~/.node-gyp` version directory from `x.y.z` to `nsolid-x.y.z`

v1.0.2 2016-12-13
================================================================================

* allow creation of bundled buildpack

v1.0.1 2016-11-03
================================================================================

* Updated to N|Solid 2.0.1

v1.0.0 2016-10-24
================================================================================

* Based on Cloud Foundry Node.js buildpack v1.5.22
* Using N|Solid 2.0.0

  * <https://github.com/cloudfoundry/nodejs-buildpack>
