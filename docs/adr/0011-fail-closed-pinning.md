# ADR 0011 — Fail-Closed Certificate Pinning em Release

## Status
Aceito

## Contexto
O app faz requisições HTTPS para a API da Cadife. Sem pinning, um atacante com acesso à cadeia de confiança do device (ex: certificado rogue, interceptação corporativa) pode realizar MITM silencioso.

## Decisão
Em builds de release (`dart.vm.product == true`), o app **obrigatoriamente** exige certificate pinning SHA-256 configurado. Se nenhum pin for fornecido ao `DioClientFactory` ou `setupServiceLocator()`, o app lança `StateError` e não inicializa a rede.

Em debug, o pinning é opcional para facilitar desenvolvimento local com certificados auto-assinados ou proxies.

## Consequências
- **Positivas:**
  - Previne MITM silencioso em produção.
  - Fica explicitamente claro durante o deploy se os pins estão faltando (crash imediato).
- **Negativas:**
  - Rotação de certificado do servidor requer atualização do app ou mecanismo de pins dinâmicos.
  - Desenvolvedores precisam configurar pins de teste ao rodar em release local.
- **Mitigação:**
  - Implementado fallback de backup pins em `SecureConfig.getCertificatePinsWithFallback()`.
  - Pins podem ser atualizados via OTA (secure storage) sem novo build.
