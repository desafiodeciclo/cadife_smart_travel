---
name: CADIFE Design System (CDS)
description: Sistema de design, identidade visual e padrões de interface para o ecossistema Cadife Smart Travel.
version: 3.0
---

# CADIFE Smart Travel — Design System (CDS) v3.0

Este documento é a **única fonte de verdade** para a interface do ecossistema Cadife. Versão otimizada para desenvolvimento ágil com Claude Code, incluindo padrões de interação, animações e dados reais.

---

## 1. DNA da Marca e Tom de Voz

*   **Personalidade:** Sofisticada, confiável, tecnológica e humana.
*   **Tom de Voz:** Consultivo e relaxante. A IA (AYA) deve soar como uma assistente de luxo: educada, direta e prestativa.
*   **Princípio de Design:** "Menos é mais". Interfaces limpas, foco em dados e estética Premium.

---

## 2. Sistema de Cores e Sombras

### 2.1 Cores de Marca
| Nome | Hex | Uso Principal |
| :--- | :--- | :--- |
| **Vermelho Cadife** | `#DD0B0E` | Primária, Botões "Entrar", CTAs. |
| **Grafite Profundo** | `#393532` | Background Dark Mode, AppBar, Navegação. |
| **Vinho Escuro** | `#53141C` | Estados "Pressed" e gradientes sutis. |
| **Laranja Vibrante** | `#FAA62A` | Alertas, Leads "Mornos". |

### 2.2 Cores Neutras e Semânticas
*   **Background (Light):** `#FFFFFF` (Pure White) ou `#F1F1F1` (Ice).
*   **Background (Dark):** `#393532`.
*   **Success (Hot Lead):** `#1E8449`.
*   **Warning (Warm Lead):** `#D35400`.
*   **Error:** `#DD0B0E` (Aparece abaixo do input com animação).

### 2.3 Sombras e Elevação (Premium Feel)
*   **Buttons:** Sombra projetada em vermelho ou preto com blur de 10px e opacidade 15-20%.
*   **Cards:** Elevação suave (`#0000001A`) com raio de borda de **20px**.

---

## 3. Tipografia e Iconografia

### 3.1 Tipografia
*   **Títulos:** `Bai Jamjuree` (Bold para H1/H2).
*   **UI/Corpo:** `Inter` (Regular para leitura, SemiBold para botões).

### 3.2 Iconografia
*   **Biblioteca:** **Lucide Icons**.
*   **Estilo:** **Linha Fina (Outline)**. Nunca use ícones preenchidos a menos que seja um estado "Ativo" na BottomNav.

---

## 4. Padrões de Interface (UI Patterns)

### 4.1 Login & Auth (Ref. v2 Image)
*   **Layout:** Centralizado. Logo grande no topo, seguido por Título (H2) e Subtítulo (Body).
*   **Campos:** Borda arredondada suave, sombra interna mínima ou borda leve. Link "Esqueci a senha" alinhado à direita acima do campo de senha.
*   **Social Login:** Seção "ou" com divisores horizontais, links para Google e Apple.

### 4.2 Formulários e Validação
*   **Erro:** O texto de erro deve aparecer **logo abaixo do input** com uma animação de fade-in ou slide-down curta.
*   **Feedback de Clique:** Efeito de **redução de escala** (o botão "esmaga" levemente para 0.95x ao ser tocado).

### 4.3 Estados de Carga e Vazio
*   **Loading:** Uso obrigatório de **Shimmer Effect** (esqueleto pulsante) em listas de leads e cards.
*   **Empty State:** SVG minimalista (ilustração linear) centralizado com um texto curto e objetivo.

---

## 5. Mídia e Motion

### 5.1 Estilo Fotográfico
*   **Mood:** Relaxante e **tons pastéis**. Evite cores muito saturadas ou vibrantes.
*   **Proporção (Aspect Ratio):** Cards de destino devem usar **16:9** (Paisagem).

### 5.2 Animações (Motion)
*   **Transição entre Telas:** As telas devem **deslizar da direita para a esquerda** (Slide).
*   **Micro-interações:** Curvas de animação suaves (`Curves.easeInOut`).

---

## 6. Dados Reais para Testes (Mock Data)

Use estes nomes para evitar Lorem Ipsum e manter o contexto da Cadife:

| Destino | Pacote/Serviço | Valor Estimado |
| :--- | :--- | :--- |
| **Lisboa Clássica** | Roteiro Histórico & Vinhos | R$ 12.500 |
| **Porto & Douro** | Experiência Vínica Premium | R$ 15.800 |
| **Algarve Verão** | Praias & Refúgios de Luxo | R$ 18.200 |
| **Sintra Mística** | Tour Privado de Palácios | R$ 4.500 |
| **Processo Visto D7** | Curadoria de Imigração | R$ 8.000 |

---

## 7. Guia de Implementação (Flutter Snippets)

```dart
// Feedback de Clique (Escala)
GestureDetector(
  onTapDown: (_) => setState(() => _scale = 0.95),
  onTapUp: (_) => setState(() => _scale = 1.0),
  child: Transform.scale(scale: _scale, child: MyButton()),
)

// Shimmer (Skeleton)
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: CardPlaceholder(),
)

// Cards com Aspect Ratio
AspectRatio(
  aspectRatio: 16 / 9,
  child: Image.asset('destinos/lisboa.jpg', fit: BoxFit.cover),
)
```

---
*Atualizado em: Abril 2026 | Foco: MVP Smart Travel*
