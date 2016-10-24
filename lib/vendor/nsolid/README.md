Files / directories in this folder:

* `install.sh`

  This script is run by `/bin/compile`, to get some bits added
  to the app being built.  It copies files in this directory into the app's
  `.nsolid-bin` and `.profile.d` directories

* `bins`

  Contains linux binaries of `cf` and `nsolid`, that will be installed
  in the app's `.nsolid-bin` directory.  Also contains `nsolid-setup.sh`, which
  is copied into the app's `.profile.d` directory, which will be run just before
  the app is launched.

* `tools`

  Contains node scripts used by the `.profile.d/nsolid-setup.sh` script, which is
  run just before the app launches.
