#!/bin/sh

# Script para trocar o GoogleService-Info.plist baseado no Flavor selecionado
# Este script deve ser adicionado como um "Run Script" no Xcode Build Phases

case "${CONFIGURATION}" in
  *staging*)
    cp -r "${PROJECT_DIR}/Runner/Firebase/Staging/GoogleService-Info.plist" "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
    echo "Firebase Staging Config selecionada"
    ;;
  *prod*)
    cp -r "${PROJECT_DIR}/Runner/Firebase/Prod/GoogleService-Info.plist" "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
    echo "Firebase Production Config selecionada"
    ;;
  *)
    cp -r "${PROJECT_DIR}/Runner/Firebase/Dev/GoogleService-Info.plist" "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
    echo "Firebase Dev Config selecionada"
    ;;
esac
