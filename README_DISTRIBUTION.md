# Build & Distribution Guide — Cadife Smart Travel

Este guia descreve como configurar o pipeline de distribuição automatizada para Android (Firebase App Distribution) e iOS (TestFlight).

## 🚀 Setup Inicial

### 1. Android Keystores
Gere os keystores locais usando o script fornecido:
```bash
cd frontend_flutter
./scripts/generate_keystores.sh
```
Isso criará os arquivos em `frontend_flutter/android/app/keystore/`. **Não commite esses arquivos.**

### 2. GitHub Secrets
Configure os seguintes secrets em **Settings → Secrets and Variables → Actions**:

| Secret | Descrição |
|---|---|
| `ENCODED_ANDROID_KEYSTORE` | Base64 do arquivo `cadife-tour.jks` (use `./scripts/encode_keystore.sh`) |
| `KEYSTORE_PASSWORD` | Senha do keystore de produção |
| `KEY_ALIAS` | Alias da chave de produção (`cadife-prod`) |
| `KEY_PASSWORD` | Senha da chave de produção |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | JSON da Service Account do Firebase com permissão de App Distribution |
| `FIREBASE_APP_ID_ANDROID_STAGING` | App ID do Android no Firebase (Staging) |
| `FIREBASE_APP_ID_ANDROID_PROD` | App ID do Android no Firebase (Produção) |
| `FIREBASE_APP_ID_IOS_STAGING` | App ID do iOS no Firebase (Staging) |
| `FIREBASE_APP_ID_IOS_PROD` | App ID do iOS no Firebase (Produção) |
| `IOS_PROVISIONING_PROFILE` | Base64 do arquivo `.mobileprovision` de distribuição |
| `SLACK_WEBHOOK` | (Opcional) URL para notificações no Slack |

### 3. Firebase Setup
1. Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
2. Habilite o **App Distribution**.
3. Adicione os Apps (Android e iOS) para Staging e Produção.
4. Baixe o `google-services.json` e coloque em `frontend_flutter/android/app/src/<flavor>/`.
5. Baixe o `GoogleService-Info.plist` e coloque em `frontend_flutter/ios/Runner/`.

## 🛠️ Build Local

Para testar o build localmente:

### Android
```bash
cd frontend_flutter
flutter build apk --flavor staging -t lib/main_staging.dart --release
```

### iOS (Requer macOS)
```bash
cd frontend_flutter
flutter build ipa --flavor staging -t lib/main_staging.dart --release
```

## 🤖 CI/CD (GitHub Actions)

O pipeline é disparado automaticamente ao fazer push para a branch `main`.
Ele realiza:
1. Setup do ambiente (Java, Flutter).
2. Decode do Keystore e Provisioning Profile.
3. Build dos flavors `staging` e `prod`.
4. Upload automático para o Firebase App Distribution.
5. Geração de artefatos (APK, AAB, IPA) no GitHub Actions.
6. Notificação via Slack.

## 👥 Gerenciamento de Testers
Os e-mails dos testers estão listados em `frontend_flutter/firebase/testers.txt`. Ao realizar um novo deploy, eles receberão um convite automaticamente.

---
*Cadife Smart Travel — Mobile Distribution System*
