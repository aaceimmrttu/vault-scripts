#!/usr/bin/env bash

_NO_SKIP_=false
VAULT_URL="vault.url.here:8200"
PROTO="https"
CA_NAME="pki"
#CA_NAME="pki_int"


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

if [ -s ca_chain.crt ]; then
  echo "CA chain file already exists"
  exit 1
fi

if [ -s ca.crt ]; then
  echo "CA file already exists"
  exit 1
fi

curl --insecure --silent -o ca_chain.crt ${PROTO}://${VAULT_URL}/v1/${CA_NAME}/ca_chain
curl --insecure --silent -o ca.crt ${PROTO}://${VAULT_URL}/v1/${CA_NAME}/ca/pem

if [ !  -s ca_chain.crt ]; then
  rm ca_chain.crt
else
  echo "Moving CA Chain to Store"
  if [ ! -s /usr/local/share/ca-certificates/ca_chain.crt ]; then
    mv ca_chain.crt /usr/local/share/ca-certificates/
    _NO_SKIP_=true
  else
    echo "CA chain already exists in store. Skipping!"
    rm -f ca_chain.crt
  fi
fi

if [ !  -s ca.crt ]; then
  rm ca_chain.crt
  echo "Unable to download certificate"
  exit 1
else
  echo "Moving CA Cert to Store"
  if [ ! -s /usr/local/share/ca-certificates/ca.crt ]; then
    mv ca.crt /usr/local/share/ca-certificates/
    _NO_SKIP_=true
  else
    echo "CA cert already exists in store. Skipping!"
    rm -f ca.crt
  fi
fi

if $_NO_SKIP_; then
  update-ca-certificates
fi
