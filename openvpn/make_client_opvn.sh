#!/bin/bash

# First argument: Client identifier
COMMON_NAME="$1"
TOKEN="$2"
VAULT_URL="vault.url.here:8200"
PROTO="https"
PKI_NAME="openvpn"
PKI_ROLE="openvpn_client_role"
TTL="720h" #30 days
TLS_CERT_NAME="ta.key"

if [ -z "$COMMON_NAME" ]; then
  echo -n "Common Name":
  read COMMON_NAME
fi

if [ -z "$TOKEN" ]; then
  echo -n Token:
  read -s TOKEN
fi

echo "Creating Certs for $COMMON_NAME"

client=`curl \
  --insecure --silent \
  -H "X-Vault-Token: $TOKEN" "Content-Type: application/json" \
  -X POST \
  -d "{\"common_name\": \"$COMMON_NAME\", \"ttl\": \"${TTL}\"}" \
  ${PROTO}://${VAULT_URL}/v1/${PKI_NAME}/issue/${PKI_ROLE}`

BASE_CONFIG=~/client_base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    <(echo -e "`echo "$client" | jq -r '.data.ca_chain[]'`") \
    <(echo -e '</ca>\n<cert>') \
    <(echo -e "`echo "$client" | jq -r '.data.certificate'`") \
    <(echo -e '</cert>\n<key>') \
    <(echo -e "`echo "$client" | jq -r '.data.private_key'`") \
    <(echo -e '</key>\n<tls-crypt>') \
    <(echo -e "`cat ${TLS_CERT_NAME}`") \
    <(echo -e '</tls-crypt>') \
    > ${COMMON_NAME}.ovpn
