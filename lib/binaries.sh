needs_resolution() {
  local semver=$1
  if ! [[ "$semver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    return 0
  else
    return 1
  fi
}

install_nodejs() {
  local requested_version="$1"
  local resolved_version=$requested_version
  local dir="$2"
  local build_dir="$3"

  if needs_resolution "$requested_version"; then
    BP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
    versions_as_json=$(ruby -e "require 'yaml'; print YAML.load_file('$BP_DIR/manifest.yml')['dependencies'].select {|dep| dep['name'] == 'node' }.map {|dep| dep['version']}")
    default_version=$($BP_DIR/compile-extensions/bin/default_version_for $BP_DIR/manifest.yml node)
    resolved_version=$($BP_DIR/bin/node $BP_DIR/lib/version_resolver.js "$requested_version" "$versions_as_json" "$default_version")
  fi

  # if [[ "$resolved_version" = "undefined" ]]; then
  #   echo "Downloading and installing node $requested_version..."
  # else
  #   echo "Downloading and installing node $resolved_version..."
  # fi
  # local heroku_url="https://s3pository.heroku.com/node/v$resolved_version/node-v$resolved_version-$os-$cpu.tar.gz"
  # local download_url=`translate_dependency_url $heroku_url`
  # local filtered_url=`filter_dependency_url $download_url`
  # curl "$download_url" --silent --fail --retry 5 --retry-max-time 15 -o /tmp/node.tar.gz || (>&2 $BP_DIR/compile-extensions/bin/recommend_dependency $heroku_url && false)
  # echo "Downloaded [$filtered_url]"
  # tar xzf /tmp/node.tar.gz -C /tmp
  # rm -rf $dir/*
  # mv /tmp/node-v$resolved_version-$os-$cpu/* $dir
  # chmod +x $dir/bin/*

  # install N|Solid via function added in lib/vendor/nsolid/install.sh
  install_nsolid "$resolved_version" "$dir" "$build_dir"
}

download_failed() {
  echo "We're unable to download the version of npm you've provided (${1})."
  echo "Please remove the npm version specification in package.json"
  exit 1
}
