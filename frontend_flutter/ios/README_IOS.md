# Configuração de Flavors no iOS (Firebase Staging)

Para que o iOS suporte múltiplos ambientes, siga estes passos no Xcode:

### 1. Criar as Build Configurations
No Xcode, selecione o projeto **Runner** (ícone azul no topo da árvore):
1. Vá na aba **Info**.
2. Na seção **Configurations**, você verá `Debug`, `Release` e `Profile`.
3. Clique no botão **+** e duplique cada uma delas renomeando para:
   - `Debug-staging`
   - `Release-staging`
   - `Profile-staging`
   - `Debug-prod`
   - `Release-prod`
   - `Profile-prod`

### 2. Adicionar o Script de Seleção de Configuração
Ainda no Xcode, no alvo **Runner**:
1. Vá na aba **Build Phases**.
2. Clique no **+** > **New Run Script Phase**.
3. Renomeie o script para `Select Firebase Config`.
4. Arraste-o para ficar logo **acima** da fase `Compile Sources`.
5. Cole o seguinte comando:
   ```bash
   "${PROJECT_DIR}/Runner/Firebase/select_firebase_config.sh"
   ```

### 3. Organizar os Arquivos Plist
Coloque cada versão do `GoogleService-Info.plist` nas pastas correspondentes que eu criei:
- `ios/Runner/Firebase/Staging/GoogleService-Info.plist`
- `ios/Runner/Firebase/Prod/GoogleService-Info.plist`
- `ios/Runner/Firebase/Dev/GoogleService-Info.plist`

**Atenção:** Não arraste o arquivo final `ios/Runner/GoogleService-Info.plist` para dentro do Xcode (ele será gerado automaticamente pelo script). Apenas as pastas dentro de `Firebase/` devem ser conhecidas pelo sistema se você quiser editá-las.

### 4. Rodar o App
Para rodar via terminal:
```bash
flutter run --flavor staging -t lib/main_staging.dart
```
