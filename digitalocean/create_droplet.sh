#!/bin/bash

set -o errexit
# set -o nounset
set -o pipefail

export auth_token="$1";
export ssh_key_name="$2";

export droplet_img="docker";

export droplet_size="512mb";
export droplet_region="sfo2";
export droplet_name_prefix="octave-docker";
export droplet_tag="octave-docker-fleet";
export droplet_name="$droplet_name_prefix-00";

# Return the fingerprint of designated SSH key.
# SSH key must already be registered to create droplets
function getSshKeyFingerpringWithName()
{
    local auth_token=$1;
    local ssh_key_name=$2;

    ssh_key_fingerprint=$(curl -s -X GET "https://api.digitalocean.com/v2/account/keys" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $auth_token" \
        | jq -r " .ssh_keys[] | select( .name == \"$ssh_key_name\" ) | .fingerprint ");

    echo $ssh_key_fingerprint;
}

# Returns all registered SSH keys
function getRegisteredSshKeyNames()
{
    local auth_token=$1;
    
    response=$(curl -s -X GET "https://api.digitalocean.com/v2/account/keys" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $auth_token");

    echo $response | jq -r " .ssh_keys[].name ";
}

function createDroplet() 
{
    local auth_token="$1";
    local ssh_key_fingerprint="$2";
    local droplet_name="$3";
    local droplet_region="$4";
    local droplet_size="$5";
    local droplet_img="$6";
    local droplet_tag="$7";

    response=$(curl -s -X POST "https://api.digitalocean.com/v2/droplets" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $auth_token" \
        -d "{\"name\":\"$droplet_name\",\"region\":\"$droplet_region\",\"size\":\"$droplet_size\",\"image\":\"$droplet_img\",\"ssh_keys\":[\"$ssh_key_fingerprint\"],\"backups\":false,\"ipv6\":false,\"user_data\":null,\"private_networking\":null,\"volumes\":null,\"tags\":[\"$droplet_tag\"]}");

    echo $response | jq  -r ' .droplet.tags '
}

function printUsage()
{
    echo "Usage: $(basename $0) <AUTH_TOKEN> <SSH_KEY_NAME>"
}

# Check essential variables
if [ "$auth_token" == "" ]; then
    printUsage;
    exit 1;
fi

if [ "$ssh_key_name" == "" ]; then
    printUsage;
    echo "Available keys are: $(getRegisteredSshKeyNames \"$auth_token\")";
    exit 1;
fi

# Grab fingerprint of current SSH key registered with Digital Ocean
ssh_key_fingerprint=$(getSshKeyFingerpringWithName "$auth_token" "$ssh_key_name");
echo "Using ssh key fingerprint: '$ssh_key_fingerprint'";

# Create droplet with spec
createDroplet "$auth_token" \
    "$ssh_key_fingerprint" \
    "$droplet_name" \
    "$droplet_region" \
    "$droplet_size" \
    "$droplet_img" \
    "$droplet_tag"
