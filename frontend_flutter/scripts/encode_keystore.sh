#!/bin/bash
# scripts/encode_keystore.sh

# This script encodes the production keystore to base64 for use in GitHub Secrets.
# It assumes the keystore exists at android/app/keystore/cadife-tour.jks

if [ ! -f "android/app/keystore/cadife-tour.jks" ]; then
    echo "❌ Error: android/app/keystore/cadife-tour.jks not found."
    exit 1
fi

# Encode keystore to base64
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows/Git Bash might need slightly different handling or it might just work
    base64 android/app/keystore/cadife-tour.jks > keystore-base64.txt
else
    base64 -i android/app/keystore/cadife-tour.jks > keystore-base64.txt
fi

echo "📋 Copie o conteúdo abaixo para GitHub Secrets → ENCODED_ANDROID_KEYSTORE:"
cat keystore-base64.txt
echo ""

# Cleanup
rm keystore-base64.txt
