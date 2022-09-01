#!/bin/bash
set -euo pipefail

HOMEDIR="/home/jekyll"
SERVERDIR="/var/www"


# Setups SSH
function setup_ssh() {
    # Create SSH directory
    mkdir -p "/etc/ssh"
    chown -R root "/etc/ssh"

    # Deploy host keys
    for KEY_TYPE in "SSH_HOST_RSA_KEY" "SSH_HOST_ECDSA_KEY" "SSH_HOST_ED25519_KEY"; do
        # Check if the key exists
        KEY="${!KEY_TYPE:-}"
        if test -n "$KEY"; then
            # Compute filename
            FILE=`echo "$KEY_TYPE" | tr "[:upper:]" "[:lower:]"`
            
            # Write private key
            echo "$KEY" > "/etc/ssh/$FILE"
            chmod u=rwX,g=,o= "/etc/ssh/$FILE"

            # Generate public key
            ssh-keygen -y -f "/etc/ssh/$FILE" > "/etc/ssh/$FILE.pub"
            chmod u=rwX,g=rX,o=rX "/etc/ssh/$FILE.pub"
        fi
    done

    # Create SSH directory
    mkdir -p "$HOMEDIR/.ssh/"
    chown -R jekyll "$HOMEDIR/.ssh/"
    chmod -R u=rwX,g=,o= "$HOMEDIR/.ssh/"

    # Write public keys
    echo "$SSH_AUTHORIZED_KEYS" > "$HOMEDIR/.ssh/authorized_keys"
    chmod -R u=rwX,g=,o= "$HOMEDIR/.ssh/"
    chmod -R u=rwX,g=rX,o=rX "$HOMEDIR/.ssh/authorized_keys"
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
    chmod -R u=rwX,g=rX,o=rX "$SERVERDIR"
}


# Prepare and start server
setup_ssh
setup_repository
exec supervisord -c "/etc/supervisord.conf"
