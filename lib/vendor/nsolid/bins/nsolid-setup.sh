# N|Solid initialization, designed to be added to app's `.profile.d` dir

echo 'initializing N|Solid'

# put nsolid on the path before the ~/.heroku/node version
export PATH=~/.heroku/nsolid/bin:$PATH

# print version of cf being used
echo "using `~/.nsolid-bin/cf --version`"

# print version of node / nsolid being used
echo "using N|Solid version `node -vv`, based on Node.js version `node -v`"

# start the tunnels
if [ "$NSOLID_CF_RUN_TUNNELS" = "false" ]; then
  echo '$NSOLID_CF_RUN_TUNNELS=false, so not running tunnels'
else
  node ~/.nsolid-bin/run-tunnels.js &
fi

# set env vars for the agent
if [ "$NSOLID_CF_RUN_AGENT" = "false" ]; then
  echo '$NSOLID_CF_RUN_AGENT=false, so not running agent'
else
  export NSOLID_APPNAME=`node ~/.nsolid-bin/compute-env-value.js NSOLID_APPNAME`
  export NSOLID_TAGS=`node ~/.nsolid-bin/compute-env-value.js NSOLID_TAGS`
  export NSOLID_COMMAND_REMOTE=`node ~/.nsolid-bin/compute-env-value.js NSOLID_COMMAND_REMOTE`
  export NSOLID_DATA_REMOTE=`node ~/.nsolid-bin/compute-env-value.js NSOLID_DATA_REMOTE`
  export NSOLID_BULK_REMOTE=`node ~/.nsolid-bin/compute-env-value.js NSOLID_BULK_REMOTE`
  export NSOLID_STORAGE_PUBKEY=`node ~/.nsolid-bin/compute-env-value.js NSOLID_STORAGE_PUBKEY`

  echo 'N|Solid environment variables:'
  set | grep NSOLID_
fi
