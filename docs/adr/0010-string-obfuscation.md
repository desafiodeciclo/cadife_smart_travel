# ADR 0010 — String Obfuscation via XOR+Base64

## Status
Aceito

## Contexto
Strings sensíveis como certificate pins, secure storage key aliases e nomes de chaves JWT apareciam em plain-text no código fonte, ficando legíveis via `strings` no binário final.

## Decisão
Implementar ofuscação leve via **XOR com chave fixa + Base64** em tempo de build. As strings ofuscadas são armazenadas como constantes `const String` e de-ofuscadas em runtime por `SecureStrings.deobfuscate()`.

## Consequências
- **Positivas:**
  - Mitiga leitura casual do binário.
  - Zero dependências externas (não usa `envied` ou code-gen pesado).
  - Auditável: qualquer dev pode replicar o XOR manualmente.
- **Negativas:**
  - Não é criptografia forte — a chave de XOR está no binário.
  - Requer re-ofuscação manual se a chave for alterada.
- **Mitigação:**
  - Usar em conjunto com `FlutterSecureStorage` para dados em runtime.
  - Considerar `envied` ou white-box crypto em futuras versões se threat model exigir.
