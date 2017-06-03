#!/bin/bash

export auth_token="FILL IN HERE WITH YOUR W/R AUTH TOKEN";
export auth_token="3e8966ef2980a84f8ae6a7c2883824749393e9e3b87d171d3b4bbd6c60c57af1";

export droplet_ssh_key="FILL IN HERE WITH YOUR SSH KEY";
export droplet_ssh_key="$(cat ~/.ssh/id_rsa.pub)"
export droplet_ssh_key_name="Reza id_rsa";

export droplet_img="docker";

export droplet_size="512mb";
export droplet_region="sfo2";
export droplet_name_prefix="octave-docker";
export droplet_tag="octave-docker-fleet";
export droplet_name="$droplet_name_prefix-00";

droplet_ssh_key_id=$(curl -X GET "https://api.digitalocean.com/v2/account/keys" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $auth_token" \
    | jq -r ' .ssh_keys[].fingerprint ')

echo "Using ssh key fingerprint: '$droplet_ssh_key_id'";

curl -X POST "https://api.digitalocean.com/v2/account/keys" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $auth_token" \
    -d "{\"id\":\"$droplet_ssh_key_name\",\"public_key\":\"$droplet_ssh_key\"}"

curl -X POST "https://api.digitalocean.com/v2/droplets" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $auth_token" \
    -d "{\"name\":\"$droplet_name\",\"region\":\"$droplet_region\",\"size\":\"$droplet_size\",\"image\":\"$droplet_img\",\"ssh_keys\":[\"$droplet_ssh_key_id\"],\"backups\":false,\"ipv6\":false,\"user_data\":null,\"private_networking\":null,\"volumes\":null,\"tags\":[\"$droplet_tag\"]}"
