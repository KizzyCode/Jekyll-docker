#!/bin/bash
set -euo pipefail

HOMEDIR="/home/jekyll"
SERVERDIR="/var/www"


# Setups the build root directory
function make_buildroot() {
    # Create the build root
    mkdir -p "$HOMEDIR/build"
    find "$HOMEDIR/build" -mindepth 1 -delete

    # Clone the repo
    git clone "$HOMEDIR/git" "$HOMEDIR/build"
}


# Build the site
function make_jekyll() {
    # Add ruby gems to environment
    export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
    export PATH="$PATH:$GEM_HOME/bin"

    # Build the site
    pushd "$HOMEDIR/build"
    bundle install
    bundle exec jekyll build
    popd

    # Ensure that we have thttpd compatible permissions
    chmod -R u=rwX,g=rX,o=rX "$HOMEDIR/build/_site"
}


# Deploy the site
function make_deploy() {
    # Create server dir
    mkdir -p "$SERVERDIR"
    find "$SERVERDIR" -mindepth 1 -delete

    # Copy/link all files
    cp -lpr "$HOMEDIR/build/_site/." "$SERVERDIR/"
}


# Build the site
make_buildroot
make_jekyll
make_deploy
