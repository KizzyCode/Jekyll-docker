#!/bin/bash
set -euo pipefail

HOMEDIR="/home/jekyll"
SERVERDIR="/var/www"


# Registers a secret SSH key for the server
function register_serverkey() {
    NAME="$1"
    KEY="$2"

    # Create SSH directory
    mkdir -p "/etc/ssh"
    chown -R root "/etc/ssh"
    
    # Write private key
    echo "$KEY" > "/etc/ssh/$NAME"
    chmod u=rwX,g=,o= "/etc/ssh/$NAME"

    # Generate public key
    ssh-keygen -y -f "/etc/ssh/$NAME" > "/etc/ssh/$NAME.pub"
    chmod u=rwX,g=rX,o=rX "/etc/ssh/$NAME.pub"
}


# Registers a public SSH key for the jekyll user
function register_userkey() {
    KEY="$1"

    # Create SSH directory
    mkdir -p "$HOMEDIR/.ssh/"
    chown -R jekyll "$HOMEDIR/.ssh/"
    chmod -R u=rwX,g=,o= "$HOMEDIR/.ssh/"

    # Write public key
    echo "$KEY" >> "$HOMEDIR/.ssh/authorized_keys"
    chmod -R u=rwX,g=,o= "$HOMEDIR/.ssh/"
    chmod -R u=rwX,g=rX,o=rX "$HOMEDIR/.ssh/authorized_keys"
}


# Applies the docker-compose environment
function setup_environment() {
    # Register server keys
    if test -n "${SSH_SERVERKEY_RSA:-}"; then
        register_serverkey "ssh_host_rsa_key" "$SSH_SERVERKEY_RSA"
    fi
    if test -n "${SSH_SERVERKEY_ECDSA:-}"; then
        register_serverkey "ssh_host_ecdsa_key" "$SSH_SERVERKEY_ECDSA"
    fi
    if test -n "${SSH_SERVERKEY_ED25519:-}"; then
        register_serverkey "ssh_host_ed25519_key" "$SSH_SERVERKEY_ED25519"
    fi

    # Register user keys
	for INDEX in `seq 0 127`; do
        # Get pubkey
        VARNAME="SSH_PUBKEY_$INDEX"
        PUBKEY="${!VARNAME:-}"

        # Register pubkey
        if test -n "$PUBKEY"; then
            register_userkey "$PUBKEY"
        fi
    done
}


# Prepares the git repository and registers the build hook if necessary
function setup_repository() {
    # Create repo if necessary and register the build hook
    git init --bare "$HOMEDIR/git"
    if ! test -e "$HOMEDIR/git/hooks/post-receive"; then
        # Link build hook
        ln -s "/libexec/jekyll-post-receive.sh" "$HOMEDIR/git/hooks/post-receive"
    fi

    # Set permissions for repo dir
    chown -R jekyll "$HOMEDIR/git"
    chmod -R u=rwX,g=,o= "$HOMEDIR/git"
    
    # Set permissions so that the build hook is able to write into $SERVERDIR
    mkdir -p "$SERVERDIR" 
    chown -R jekyll "$SERVERDIR"
    chmod -R u=rwX,g=X,o=X "$SERVERDIR"
}


# Prepare and start server
setup_environment
setup_repository
exec supervisord -c "/etc/supervisord.conf"
