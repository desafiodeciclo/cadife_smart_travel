#!/bin/bash
# scripts/generate_keystores.sh

set -e

# Ensure we are in the frontend_flutter directory or at least can find android/app/keystore
# This script assumes it's being run from the frontend_flutter directory

# Dev keystore
keytool -genkey -v \
  -keystore android/app/keystore/cadife-tour-dev.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cadife-dev \
  -storepass "${KEYSTORE_PASSWORD_DEV:-password123}" \
  -keypass "${KEY_PASSWORD_DEV:-password123}" \
  -dname "CN=Cadife Dev,O=Cadife,C=BR"

# Staging keystore
keytool -genkey -v \
  -keystore android/app/keystore/cadife-tour-staging.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cadife-staging \
  -storepass "${KEYSTORE_PASSWORD_STAGING:-password123}" \
  -keypass "${KEY_PASSWORD_STAGING:-password123}" \
  -dname "CN=Cadife Staging,O=Cadife,C=BR"

# Prod keystore
keytool -genkey -v \
  -keystore android/app/keystore/cadife-tour.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias cadife-prod \
  -storepass "${KEYSTORE_PASSWORD:-password123}" \
  -keypass "${KEY_PASSWORD:-password123}" \
  -dname "CN=Cadife Tour,O=Cadife,C=BR"

echo "✅ Keystores gerados com sucesso em android/app/keystore/"
