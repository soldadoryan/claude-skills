#!/usr/bin/env bash
set -e
DEST="${1:-$HOME/.claude/skills}/perfect-app"
mkdir -p "$DEST/references" "$DEST/scripts"

cat > "$DEST/SKILL.md" <<'PERFECT_APP_EOF'
---
name: perfect-app
description: Refaz sites, landing pages e apps web com "cara de IA" até parecerem produzidos por um time sênior (designer, front-end, QA, SEO e cybersec) — design system com escala tipográfica modular, grid de 8pt, cores OKLCH, foco total em conversão, WCAG 2.2 AA, Core Web Vitals, security headers/CSP — e no fim humaniza o código (remove comentários, plan.md e vestígios de IA, renomeia variáveis/componentes como um dev humano) e cria o llms.txt. Use SEMPRE que o usuário digitar /perfect-app, pedir para "deixar o site profissional", "tirar a cara de IA", "de-slop", "parece vibe-coded", "melhorar o layout/landing page", "deixar mais bonito/elegante/moderno", "aumentar conversão", "polir o front", ou mandar um projeto/print de site pedindo redesign — mesmo sem citar a skill.
---

# /perfect-app

Você vai transformar uma interface genérica — o tipo de layout que qualquer pessoa reconhece como "foi uma IA que fez" — num produto que parece ter passado por um estúdio de design, um time de front-end sênior, QA, um consultor de SEO e um pentester. O critério de sucesso é um só: **um visitante desconfiado não consegue apontar nada que denuncie automação, e a página converte melhor do que antes.**

Interfaces geradas por IA ficam iguais porque o modelo amostra o padrão mais provável do corpus de treino: Inter em tudo, gradiente roxo→azul, três cards iguais em linha, hero centralizado, `rounded-2xl` com sombra suave, emoji como ícone, copy vaga ("Build the future"). Genérico, num mercado competitivo, é invisível. O antídoto não é "evitar a lista negra" — é **tomar decisões deliberadas e sistemáticas**, como um profissional faria, e deixar o sistema (tokens) forçar consistência.

## Antes de começar

Leia as referências conforme a fase pede — não todas de uma vez:

| Arquivo | Quando ler |
|---|---|
| `references/ai-tells.md` | Fase 1 (diagnóstico) e Fase 3 (de-slop) |
| `references/design-system.md` | Fase 2 (tokens, tipografia, espaçamento, cor, motion) |
| `references/conversion.md` | Fase 4 (arquitetura da página, copy, CTA, formulários) |
| `references/frontend-qa.md` | Fases 5 e 6 (performance, a11y WCAG 2.2, testes) |
| `references/seo.md` | Fase 7 |
| `references/security.md` | Fase 8 |
| `references/humanize-code.md` | Fase 9 (limpeza, naming, llms.txt) |

Scripts (rode, não reescreva):
- `scripts/scan_ai_tells.py <dir>` — detecta padrões visuais, de copy e de código típicos de IA. Rode no início (baseline) e no fim (prova).
- `scripts/strip_ai_traces.py <dir>` — remove comentários preservando diretivas, e lista arquivos de vestígio (plan.md etc). **Dry-run por padrão**; `--apply` executa.
- `scripts/generate_llms_txt.py <dir> --site-url https://...` — gera `llms.txt` a partir do HTML buildado ou das rotas.

Os scripts estão em `<diretório desta skill>/scripts/`. Use caminhos absolutos. Só usam Python 3 da biblioteca padrão; para JS/TS/JSX o `strip_ai_traces.py` precisa de Node e instala sozinho o `@babel/parser` em `~/.cache/perfect-app` na primeira execução (parser real, então URLs em texto JSX, regex e template strings não são confundidos com comentários). Arquivos que não parsearem ficam intactos e aparecem no relatório.

Monte uma lista de tarefas (TaskCreate) com as fases abaixo — o trabalho é longo e o usuário acompanha por ela.

## Fase 0 — Reconhecimento

1. Identifique stack (Next/React/Vue/Svelte/Astro/HTML puro, Tailwind/CSS Modules/styled), gerenciador de pacotes e scripts (`build`, `lint`, `typecheck`, `test`).
2. Rode o build antes de mexer em qualquer coisa. Se já quebra, anote — você não quer herdar a culpa nem confundir regressões.
3. Rode `scan_ai_tells.py` e guarde o relatório como baseline (fora do projeto, no scratchpad).
4. Se houver navegador disponível, abra a página e veja em 375px, 768px, 1280px e 1440px. Screenshots valem mais que ler JSX.
5. Se o projeto usa git, confirme que a árvore está limpa ou avise o usuário — a Fase 9 mexe em muitos arquivos e ele vai querer um diff revisável.

## Fase 1 — Brief e direção

Um designer sênior não começa pelo pixel, começa pelo porquê. Extraia (do conteúdo existente, ou pergunte em **uma** rodada curta se faltar algo decisivo):

- **Produto e oferta**: o que é vendido, para quem, por quanto.
- **Objetivo de conversão único** (o "One Goal"): comprar, agendar, cadastrar, pedir orçamento, baixar. Uma página, uma ação primária.
- **Público e nível de consciência** (Eugene Schwartz: unaware → most aware). Define quanto a página precisa educar antes de pedir.
- **Marca existente**: logo, cores, fontes. Se existir, respeite e eleve; não invente outra identidade.
- **Objeções principais** (preço, confiança, complexidade, tempo) — viram seções.

Depois **comprometa-se com uma direção estética** e escreva-a em 2–3 linhas para você mesmo (não precisa virar arquivo). Exemplos de direções com personalidade, cada uma com tipografia, paleta e ritmo próprios: editorial/revista, suíço/grid rigoroso, luxo discreto (serifas, muito respiro), técnico/instrumental (mono + grid denso), orgânico/artesanal, brutalista refinado, institucional confiável. Escolha pela marca e pelo público — um escritório de advocacia e um app de fitness não podem sair com o mesmo layout. Neutralidade genérica é exatamente o que denuncia IA.

## Fase 2 — Design system (tokens primeiro)

Tudo que vem depois consome tokens; nenhum valor mágico solto no código. Leia `references/design-system.md` e defina, como CSS custom properties (ou `theme` do Tailwind):

- **Tipografia**: par de fontes intencional (display com caráter + texto legível), escala modular com razão explícita (ex. 1.25 Major Third para UI, 1.333 Perfect Fourth para marketing), tamanhos fluidos com `clamp()`, `line-height` sem unidade decrescendo conforme o tamanho cresce, medida de 45–75 caracteres (`max-width: 65ch`), `letter-spacing` negativo em displays grandes, `font-variant-numeric: tabular-nums` em números.
- **Espaçamento**: grid de 8pt com sub-passo de 4 (`4, 8, 12, 16, 24, 32, 48, 64, 96, 128`). Ritmo vertical entre seções maior que dentro delas (lei da proximidade — Gestalt).
- **Cor**: OKLCH, paleta com 1 cor de marca, 1 acento opcional, neutros levemente tingidos pela matiz da marca (nunca cinza puro `#888`), tokens semânticos (`--color-surface`, `--color-text-muted`, `--color-action`), contraste AA verificado. Regra 60-30-10.
- **Forma**: raio consistente e proporcional (escala curta, ex. 2/6/12 — não `rounded-2xl` em tudo), sombras em camadas com a cor da superfície (não `rgba(0,0,0,.1)` genérico), bordas finas tingidas.
- **Motion**: durações 120–320ms, easing curvo (`cubic-bezier(.2,.7,.2,1)`), só `transform`/`opacity`, `prefers-reduced-motion` respeitado.
- **Layout**: container com max-width, grid de 12 colunas no desktop, breakpoints por conteúdo e não por device.

## Fase 3 — De-slop (remover a cara de IA)

Com `references/ai-tells.md` aberto, percorra o relatório do scanner e a página item a item. As categorias:

1. **Visual**: gradientes roxo/azul sem semântica, gradient text, glassmorphism gratuito, blobs/auroras de fundo, grid de cards idênticos, hero centralizado sobre imagem escura, badges/pills/"dots" de status em tudo, borda colorida grossa em um lado do card, ícones emoji, sombras genéricas, tudo com o mesmo peso visual.
2. **Tipografia**: Inter/Roboto/system como display, tudo em 16px, hierarquia plana, headings em Title Case com gradiente.
3. **Layout**: simetria perfeita em todas as seções, seções todas com a mesma altura e o mesmo padrão "título centralizado + subtítulo + 3 colunas", ausência de quebra de grid intencional.
4. **Copy**: "Unlock", "Elevate", "Seamless", "Revolutionize", "Build the future", "Scale without limits", tríades retóricas, travessões em excesso, placeholders (John Doe, Acme, Lorem ipsum, 99.9% inventado), depoimentos genéricos sem nome/cargo/foto.
5. **Estados**: só o "happy path" desenhado — sem loading, vazio, erro, hover/focus/active/disabled.

Não troque um clichê por outro (ex. tirar roxo e pôr ciano neon). Cada substituição deve vir dos tokens da Fase 2 e da direção da Fase 1. A pergunta para cada elemento é: *"um diretor de arte aprovaria isso para este cliente específico?"*

## Fase 4 — Conversão

Leia `references/conversion.md`. O essencial:

- **Above the fold**: headline com a promessa específica (resultado + para quem), subheadline que remove a principal objeção, CTA primário inconfundível, prova social imediata (logos, nota, número real), visual que mostra o produto ou o resultado — não ilustração abstrata.
- **Arquitetura narrativa** (ex. PAS ou AIDA): problema → solução → como funciona → prova → oferta → objeções (FAQ) → CTA final. Cada seção responde uma objeção.
- **CTA**: verbo + benefício ("Agendar minha avaliação", não "Enviar"), cor de ação exclusiva, repetido em pontos de decisão, microcopy de redução de risco abaixo ("Sem cartão. Cancele quando quiser.").
- **Formulários**: mínimo de campos, labels visíveis, validação inline, `autocomplete` correto, teclado certo no mobile (`inputmode`), estado de sucesso claro.
- **Hierarquia visual**: padrão F/Z, contraste de tamanho/peso/cor guiando o olho até o CTA. Lei de Hick (menos escolhas), Lei de Fitts (alvos grandes e próximos).
- Nunca invente depoimentos, números ou logos de clientes. Use placeholders explícitos e marque-os para o usuário preencher — prova social falsa destrói confiança e pode ser ilegal.

## Fase 5 — Engenharia front-end

Leia `references/frontend-qa.md`. HTML semântico (landmarks, um `h1`, ordem de headings), componentes com responsabilidade clara, CSS a partir de tokens, imagens responsivas (`srcset`, AVIF/WebP, `width`/`height` explícitos, `fetchpriority="high"` só no LCP, `loading="lazy"` abaixo da dobra), fontes com `font-display: swap` + preload + subset + fallback com métricas ajustadas (`size-adjust`) para zerar CLS. Metas: **LCP ≤ 2,5s, INP ≤ 200ms, CLS ≤ 0,1** (p75, mobile).

## Fase 6 — QA e acessibilidade (WCAG 2.2 AA)

Contraste 4.5:1 texto / 3:1 UI e texto grande, alvos ≥ 24×24px (mire 44×44 em mobile), foco visível e não obscurecido por header fixo/banners, navegação completa por teclado, `alt` significativo, `prefers-reduced-motion`, zoom 200% sem quebra, sem scroll horizontal em 320px. Teste os estados (loading/vazio/erro/sucesso) e os breakpoints. Rode lint, typecheck, testes e build; corrija o que você quebrou.

## Fase 7 — SEO

Leia `references/seo.md`: `title` (≤ 60 car.) e `meta description` (≤ 155) únicos por página, canonical, Open Graph/Twitter completos, JSON-LD adequado (Organization, LocalBusiness, Product, FAQPage, BreadcrumbList), `sitemap.xml`, `robots.txt`, `lang` correto, URLs limpas, headings com intenção de busca, links internos descritivos.

## Fase 8 — Segurança

Leia `references/security.md`: security headers (CSP restritiva com nonce/hash, HSTS, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`, `frame-ancestors`), nada de segredo no bundle do cliente (`NEXT_PUBLIC_`/`VITE_` só para o que é público), formulários com validação no servidor + honeypot/rate limit, `rel="noopener noreferrer"` em links externos, sanitização de qualquer HTML dinâmico, `npm audit`/dependências atualizadas, sem `eval`/`dangerouslySetInnerHTML` sem sanitizar. Configure os headers no lugar certo da hospedagem (vercel.json, netlify `_headers`, nginx, middleware).

Depois percorra o **Checklist de segurança** inteiro no fim de `references/security.md` (11 seções: transporte, headers, segredos, XSS, formulários, autenticação, APIs, dependências, LGPD, infraestrutura, verificação final). Marque cada item como ✅ feito, ➖ não se aplica ou ⏳ depende do usuário — só marque ✅ depois de verificar de verdade. O relatório final traz o placar do checklist e a lista dos ⏳ com o que o usuário precisa fazer ou testar após o deploy. Seja honesto: front-end bem feito reduz superfície, não garante "100% seguro".

## Fase 9 — Humanização do código e llms.txt

Leia `references/humanize-code.md`. Ordem segura:

1. **Renomeie** identificadores com cara de IA (ex. `handleButtonClickEvent` → `submit`, `userDataObject` → `user`, `HeroSectionComponent` → `Hero`, `.feature-card-item-wrapper` → `.feature`). Use rename do LSP/IDE ou faça busca exaustiva; nomes curtos, do domínio do negócio, convenção da linguagem. Rode typecheck/build depois de cada lote.
2. **Remova comentários** com `strip_ai_traces.py <dir>` (dry-run → revise → `--apply`). O script preserva shebang, licenças (`/*! */`, `@license`), diretivas de lint/TS/prettier, magic comments de bundler, comentários condicionais HTML e `"use client"`.
3. **Vestígios**: o mesmo script lista plan.md, PLAN.md, IMPLEMENTATION*.md, progress/summary de agentes, `*.bak`, logs, rodapés "Generated with…", `console.log` de debug, `<meta name="generator">` de ferramentas de IA. Mostre a lista ao usuário e só apague após o "ok" dele — deletar é irreversível. **Preserve sempre** `.claude/` (skills, settings), `CLAUDE.md`, `AGENTS.md`/`Agent.md`/`agent.md`, `.github/`, `README` (reescreva em tom humano se estiver robótico) e `LICENSE`.
4. **llms.txt**: gere com `generate_llms_txt.py` e revise à mão — o arquivo vive em `public/llms.txt` (ou na raiz do output estático) e segue o formato llmstxt.org: H1 com o nome, blockquote com resumo, seções H2 com links curados e uma linha de descrição cada. Se o usuário escreveu "LLM.txt", o nome correto do padrão é `llms.txt`; crie esse.
5. Rode build/lint/testes de novo e `scan_ai_tells.py` para provar que os padrões caíram.

## Fase 10 — Revisão do painel e entrega

Antes de entregar, revise a página como cada especialista faria, rapidamente e de verdade:
- **Diretor de arte**: há uma ideia visual clara? Hierarquia, ritmo e respiro consistentes? Algo ainda parece template?
- **Front-end sênior**: tokens usados em tudo? Sem valores mágicos? Componentes enxutos?
- **QA**: estados, breakpoints, teclado, contraste, build verde?
- **SEO**: metadados, schema, sitemap, CWV?
- **Cybersec**: headers, segredos, formulários, dependências?
- **CRO**: o CTA é inevitável? Cada objeção tem resposta?

Relatório final curto (no chat): o que mudou em cada frente, antes/depois do scanner, pendências que dependem do usuário (depoimentos reais, fotos, domínio para headers/HSTS, chaves de analytics), e o que testar em produção (Lighthouse/PageSpeed, securityheaders.com). Sem recapitular passo a passo.

## Princípios que valem o tempo todo

- **Decida, não decore.** Cada cor, fonte, espaço e animação precisa de um motivo ligado à marca, ao público ou à conversão.
- **Sistema acima de exceções.** Se precisou de um valor fora da escala, a escala está errada — ajuste o token.
- **Conteúdo real dirige o design.** Use o texto e as imagens do cliente; placeholder fica marcado como pendência.
- **Não quebre o que funciona.** Build verde antes e depois; mudanças grandes em lotes verificáveis.
- **Honestidade com o usuário.** Não invente métricas, depoimentos ou garantias de segurança.
PERFECT_APP_EOF

cat > "$DEST/references/ai-tells.md" <<'PERFECT_APP_EOF'
# Catálogo de "AI tells" e o que colocar no lugar

Cada item: o sinal → por que denuncia → a substituição profissional. A presença de um item isolado não prova nada; o acúmulo é o que cria a "cara de IA". Elimine o máximo possível, priorizando os de severidade alta.

## Índice
1. Cor e superfícies
2. Tipografia
3. Layout e composição
4. Componentes e detalhes
5. Iconografia e imagem
6. Motion e interação
7. Copy e conteúdo
8. Estados e bordas do produto

---

## 1. Cor e superfícies

| Sinal (severidade) | Por que denuncia | Substituição |
|---|---|---|
| Gradiente roxo→azul / violet→indigo em hero, botão ou fundo (alta) | É o gradiente estatisticamente mais comum em marketing tech; herança dos defaults `indigo-500` do Tailwind | Cor sólida de marca. Gradiente só com função (indicar direção, profundidade, um único ponto focal) e entre matizes vizinhas da própria paleta |
| Gradient text (`background-clip: text`) em headings/métricas (alta) | Clichê, prejudica legibilidade e contraste | Texto sólido; ênfase por peso, tamanho, itálico da fonte display ou uma palavra na cor de acento |
| Glassmorphism (`backdrop-filter: blur`) em cards sem camada real por trás (média) | Efeito decorativo sem semântica | Superfície opaca com elevação definida por token; vidro só em overlays sobre conteúdo real (nav fixa sobre imagem) |
| Blobs/auroras/radial glows flutuando no fundo (alta) | "Assinatura" de landing gerada | Fundo neutro tingido, textura sutil (grain/noise a 2–4%), fotografia real, ou um elemento gráfico da marca |
| Dark mode neon com 4+ cores vibrantes (alta) | Ninguém escolheu uma cor principal | 1 cor de marca + neutros; acento usado em ≤ 10% da área |
| Cinza puro (`#6b7280`, `#888`) em textos e bordas (baixa) | Defaults de framework | Neutros OKLCH com croma 0.005–0.02 na matiz da marca |
| Borda gradiente de 1px "premium" (média) | Usado tanto que perdeu sentido | Borda sólida tingida `oklch(… / .12)` ou hairline interna via `box-shadow: inset` |
| CTA roxo/índigo genérico (média) | Padrão medido em sites vibe-coded | Cor de ação exclusiva derivada da marca, usada só em ações primárias |

## 2. Tipografia

| Sinal | Substituição |
|---|---|
| Inter/Roboto/Arial/system-ui como fonte de display (alta) | Display com personalidade alinhada à direção (ver design-system.md §2). Inter pode ficar no texto corrido se fizer sentido |
| Tudo em 16px / hierarquia plana | Escala modular com contraste real: display 3–5× o body |
| Headings centralizados em todas as seções | Alinhamento à esquerda como padrão; centralizar só onde há intenção (hero curto, CTA final) |
| Title Case Em Todas As Palavras em PT-BR | Sentence case (padrão editorial em português) |
| `letter-spacing` padrão em displays grandes | `-0.02em` a `-0.04em` em ≥ 40px; `+0.06em` a `+0.12em` em small caps/overlines |
| Overline "✨ NEW FEATURE" pill acima de todo título | Overline só quando agrega (categoria, numeração de seção), sem emoji |
| Linhas de 100+ caracteres | `max-width: 60–70ch` no texto corrido |
| Viúvas/órfãs em headlines | `text-wrap: balance` em headings, `text-wrap: pretty` em parágrafos |

## 3. Layout e composição

| Sinal | Substituição |
|---|---|
| Três (ou seis) cards idênticos em linha para features (alta) | Bento grid com tamanhos diferentes pela importância; lista alternada texto/imagem; feature principal destacada + secundárias em lista; tabela comparativa |
| Hero centralizado sobre imagem escura com overlay | Hero assimétrico (texto 5–6 col, visual 6–7 col), produto real em contexto, ou tipográfico puro com display grande |
| Toda seção = título centralizado + subtítulo + grid | Variar o ritmo: seção densa → seção de respiro → citação grande → números → CTA. Quebrar o grid de propósito em 1–2 momentos |
| "Hero metric" (número gigante + label + 3 stats + linha gradiente) | Números integrados à narrativa, com fonte e contexto ("312 clínicas em MG desde 2021") |
| Espaçamentos arbitrários (`py-20`, `py-24`, `mt-7` misturados) | Tokens de espaçamento de seção fixos (ex. 96/128px desktop, 64/80 mobile) |
| Simetria perfeita em tudo | Tensão controlada: assimetria no grid, alinhamento óptico, sobreposição intencional |

## 4. Componentes e detalhes

| Sinal | Substituição |
|---|---|
| `rounded-2xl` + `shadow-lg` em todos os elementos (alta) | Escala curta de raio coerente com a direção (pode ser 0); sombra em camadas só onde há elevação real |
| shadcn/ui ou template sem nenhuma customização | Re-tematizar via tokens: raio, fonte, cores, densidade, estados |
| Card com borda grossa colorida em um lado só | Separador hairline, número/índice tipográfico, ou fundo tonal |
| Badges/pills/"Live" dots espalhados | Badge só para status real e acionável |
| Botões com gradiente e glow | Botão sólido, altura 44–52px, padding horizontal ≈ 2× vertical, estados hover/active/focus/disabled distintos |
| Todos os botões com o mesmo peso visual | Hierarquia: primário (cheio), secundário (contorno/tonal), terciário (link) |
| Toggle "Monthly/Yearly -20%" + 3 planos com o do meio "Most popular" brilhando | Se precisar de pricing, ancoragem honesta, destaque sóbrio, comparação de features em tabela |

## 5. Iconografia e imagem

| Sinal | Substituição |
|---|---|
| Emojis como ícones (🚀 ⚡ ✨ 🔒) (alta) | Um único set de ícones (Lucide, Phosphor, Tabler…) com stroke e tamanho por token, ou nenhum ícone |
| Ícone dentro de quadrado colorido arredondado em todo card | Ícone solto alinhado à linha de base do título, ou ilustração própria |
| Ilustrações 3D genéricas / imagens de IA perfeitas demais | Foto real do produto, equipe, cliente; screenshot real da UI; ilustração com estilo único |
| Mockup de dashboard falso | Screenshot real, ou crop focado na funcionalidade que vende |
| Imagens sem `width/height`, sem `alt` | Ver frontend-qa.md |

## 6. Motion e interação

| Sinal | Substituição |
|---|---|
| Fade-in-up em todos os elementos ao rolar | Animação só em momentos de narrativa ou feedback; stagger curto (40–60ms) e uma vez |
| Hover que só aumenta escala (`scale-105`) em tudo | Feedback coerente: mudança de superfície, sublinhado animado, deslocamento de ícone 2–4px |
| Durações longas (500ms+), easing linear | 120–320ms, curvas ease-out; `prefers-reduced-motion` desliga |
| Cursor custom, partículas, parallax pesado | Remover, salvo direção explicitamente expressiva |

## 7. Copy e conteúdo

Palavras e construções a eliminar (EN/PT): unlock, elevate, seamless, effortless, revolutionize, supercharge, empower, leverage, cutting-edge, game-changer, next-level, "in today's fast-paced world", "build the future of X", "scale without limits", "your all-in-one solution", "desbloqueie", "eleve", "revolucione", "potencialize", "solução completa", "no mundo de hoje".

Padrões a eliminar:
- Tríades em todo lugar ("Rápido. Simples. Poderoso.").
- Travessões (—) em excesso; perguntas retóricas em sequência.
- Placeholders: John Doe, Jane Smith, Acme, Lorem ipsum, "Company Name", "+1 (555)", métricas redondas inventadas (10x, 99.9%, 10.000+ usuários).
- Depoimento sem nome completo, cargo, empresa e foto.
- Features descritas como features ("IA avançada") em vez de resultados ("responde o cliente em 30 segundos, mesmo de madrugada").
- Microcopy genérico de botão: "Submit", "Get started", "Learn more", "Saiba mais".

Substitua por: especificidade (números reais, lugares, prazos), voz da marca, benefício concreto, linguagem do cliente (como ele descreve o problema).

## 8. Estados e bordas do produto

IA desenha só o caminho feliz. Um produto profissional tem:
- Loading (skeleton com as dimensões finais — evita CLS), vazio (com ação sugerida), erro (o que houve + como resolver), sucesso (próximo passo).
- Hover, focus-visible, active, disabled, aria-busy em cada controle.
- Textos longos, nomes com acento, telas de 320px, zoom de 200%.
- Favicon/apple-touch-icon/manifest, página 404 desenhada, `<title>` real (não "Vite + React" / "Create Next App").
PERFECT_APP_EOF

cat > "$DEST/references/conversion.md" <<'PERFECT_APP_EOF'
# Conversão (CRO)

## Princípios
- **One Goal Rule**: uma página, uma oferta, uma ação primária. Ações secundárias existem, mas visualmente subordinadas. Em landing de campanha, considere remover a navegação.
- **Message match**: a headline precisa ecoar a promessa do anúncio/link que trouxe o visitante.
- **Clareza > criatividade** no primeiro viewport: em ~5 segundos o visitante precisa saber o que é, para quem é, e o que fazer.
- **Benefício > feature**: descreva o resultado no mundo do cliente.
- **Reduzir risco percebido** perto de cada CTA: garantia, sem cartão, cancelamento livre, prazo, LGPD.
- **Velocidade é conversão**: cada segundo extra de carregamento derruba conversão; landing deve ficar visível em < 2,5s no 4G.

## Arquitetura de landing (ordem padrão, adapte)
1. **Hero**: headline (promessa específica, 6–12 palavras), subheadline (como/para quem/objeção principal, 1–2 linhas), CTA primário + secundário opcional, microcopy de risco, prova social imediata (nota com número de avaliações, logos, "+N clientes" real), visual do produto/resultado.
2. **Barra de prova**: logos de clientes/mídia em tons neutros, nunca coloridos competindo com o CTA.
3. **Problema / agitação**: a dor nas palavras do cliente (PAS: Problem → Agitate → Solve).
4. **Solução / como funciona**: 3–4 passos numerados, concretos.
5. **Benefícios principais**: feature principal destacada com visual real + secundárias em lista. Evite grid de cards iguais.
6. **Prova social profunda**: depoimentos com nome, cargo, empresa, foto e resultado mensurável; estudo de caso; antes/depois.
7. **Oferta / preço**: ancoragem honesta, o que está incluso, garantia.
8. **FAQ**: responde as objeções reais (preço, prazo, suporte, segurança, cancelamento). Marque com `FAQPage` JSON-LD.
9. **CTA final**: repete a promessa + ação + redução de risco.
10. **Rodapé**: contato, CNPJ/endereço quando local, políticas (privacidade, termos), redes. Sinais de confiança.

## Hero — checklist
- Headline específica: "Contabilidade para clínicas médicas em BH, sem surpresas no fim do mês" > "Soluções contábeis inovadoras".
- CTA com verbo de primeira pessoa + benefício: "Quero minha proposta", "Agendar avaliação gratuita", "Ver planos".
- Um CTA primário visível sem rolar em 375×667.
- Visual: produto real, pessoa real usando, ou resultado. Olhar da pessoa direcionado ao CTA (direcionamento de atenção).
- Prova social a ≤ 1 rolagem do topo.

## CTA
- Cor de ação exclusiva (não usada em nada não clicável), contraste alto com o entorno.
- Altura ≥ 44px, largura confortável, área de toque generosa; full-width no mobile quando é o CTA principal.
- Repetir a cada 1–2 seções em páginas longas; sticky CTA discreto no mobile após o hero.
- Estados: hover, active, focus-visible, loading (com `aria-busy`), disabled só quando inevitável.

## Formulários
- Pergunte só o necessário agora; o resto depois (progressive profiling). Cada campo a menos tende a aumentar conclusão.
- Labels visíveis acima do campo (placeholder não é label). Uma coluna.
- `type`, `inputmode`, `autocomplete` corretos (`email`, `tel`, `name`, `postal-code`, `one-time-code`).
- Validação inline no blur, mensagens que dizem como corrigir, preservar dados em erro.
- Máscaras leves (telefone BR, CEP) sem bloquear colagem.
- Multi-step com indicador de progresso quando > 5 campos.
- Sucesso: confirmação clara + próximo passo (ex. "Você receberá no WhatsApp em até 1h").
- Integração: WhatsApp click-to-chat é um CTA de alta conversão no Brasil — considere como secundário.

## Psicologia aplicada (com ética)
- **Hick**: menos opções → decisão mais rápida.
- **Fitts**: alvos grandes e próximos de onde o olhar está.
- **Von Restorff**: o CTA deve ser o elemento mais diferente da página.
- **Prova social, autoridade, reciprocidade** (conteúdo útil, diagnóstico gratuito).
- **Ancoragem** no pricing com transparência.
- Escassez/urgência só se forem reais. Contadores falsos, dark patterns e prova social inventada estão fora — prejudicam marca e podem violar o CDC.

## Mensuração (deixar pronto, não inventar chaves)
- Eventos: clique no CTA, início e envio de formulário, clique no WhatsApp, rolagem 50/90%.
- Atributos `data-track="cta-hero"` ou equivalente para o usuário plugar GA4/GTM/Meta Pixel.
- Sugira hipóteses de teste A/B no relatório (headline, CTA, prova social no hero).
PERFECT_APP_EOF

cat > "$DEST/references/design-system.md" <<'PERFECT_APP_EOF'
# Design system: tokens e fundamentos

Defina tudo como custom properties em `:root` (ou no `theme.extend` do Tailwind, apontando para as custom properties). Nomes semânticos, por propósito — não por aparência (`--color-action`, não `--purple`).

## Índice
1. Escala tipográfica
2. Escolha e pareamento de fontes
3. Espaçamento (8pt)
4. Cor (OKLCH)
5. Forma: raio, borda, sombra
6. Layout e grid
7. Motion
8. Modelo de tokens pronto

---

## 1. Escala tipográfica

Escala modular: cada passo = anterior × razão. Escolha a razão pela densidade:

| Razão | Nome | Uso |
|---|---|---|
| 1.125 | Major Second | Dashboards, apps densos |
| 1.200 | Minor Third | Produto/UI |
| 1.250 | Major Third | Sites institucionais, docs |
| 1.333 | Perfect Fourth | Marketing, landing pages |
| 1.500 | Perfect Fifth | Editorial, luxo, contraste dramático |

Tamanhos fluidos com `clamp(min, preferido, max)` interpolando entre ~360px e ~1440px de viewport. Fórmula do valor preferido: `slope = (max - min) / (1440 - 360)`; `preferido = min - slope*360 + slope*100vw` (converta para rem). Sempre `rem` no min/max para respeitar o zoom do usuário.

Line-height sem unidade, inversamente proporcional ao tamanho:
- Body 16–18px: 1.5–1.65
- Subtítulos 20–28px: 1.3–1.4
- Headings 32–48px: 1.1–1.2
- Display 56px+: 0.95–1.05

Medida: 45–75 caracteres por linha em coluna única (Bringhurst); 40–50 em multicolunas. `max-width: 65ch` no parágrafo.

Ajustes finos: `letter-spacing` negativo em display (−0.02 a −0.04em), positivo em caps pequenas; `font-feature-settings`/`font-variant-numeric: tabular-nums` em preços e tabelas; `text-wrap: balance` em headings; `hanging-punctuation` quando suportado; `font-optical-sizing: auto` em variáveis.

Peso: no máximo 3 pesos por família na página (ex. 400, 500/600, 700). Hierarquia vem de tamanho + peso + cor + espaço, não só de tamanho.

## 2. Escolha e pareamento de fontes

Pareie por contraste de estrutura e afinidade de proporção (altura-x parecida). Use fontes de Google Fonts/Fontsource auto-hospedadas (performance e privacidade/LGPD). Exemplos por direção — ponto de partida, não regra:

- **Editorial**: Fraunces, Newsreader, Instrument Serif (display) + Inter Tight, Source Sans 3 (texto)
- **Suíço/grid**: Neue Haas–like (Inter Tight, Manrope, Geist) display pesado + mesmo família no texto, com escala dramática
- **Luxo discreto**: Cormorant Garamond, Playfair Display, Bodoni Moda + Jost, Karla
- **Técnico/instrumental**: Space Grotesk, IBM Plex Sans + IBM Plex Mono, JetBrains Mono para dados
- **Orgânico/humano**: DM Serif Display, Recoleta-like (Young Serif) + Nunito Sans, Figtree
- **Institucional confiável**: Source Serif 4, Libre Caslon + Public Sans, IBM Plex Sans
- **Brutalista refinado**: Archivo/Archivo Black, Unbounded + Space Mono

Carregamento: `woff2`, subset `latin` + `latin-ext` (acentos PT), `font-display: swap`, `<link rel="preload">` só da fonte acima da dobra, fallback com `size-adjust`/`ascent-override` (ou `next/font`, que faz isso) para CLS zero.

## 3. Espaçamento (8pt)

Base 8 com meio-passo 4. Escala sugerida (px): `0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96, 128, 160`.

Regras:
- Proximidade (Gestalt): espaço interno de um grupo < espaço entre grupos. Ex.: label→input 8, campo→campo 16–24, bloco→bloco 48–64, seção→seção 96–160.
- Padding de componente: vertical:horizontal ≈ 1:2 em botões (ex. 12/24), 1:1 em cards (24/24, 32/32).
- Seções: token único `--space-section` fluido (ex. `clamp(4rem, 2.5rem + 6vw, 9rem)`).
- Alinhe tudo a múltiplos de 4; alturas de controle 40/44/48/52.
- Nada de `margin` aleatório para "consertar" alinhamento — ajuste o token ou use `gap`.

## 4. Cor (OKLCH)

OKLCH dá luminosidade perceptualmente uniforme: dá para gerar escalas previsíveis e garantir contraste mudando só `L`.

Estrutura:
- **Marca** (`--brand-*`): 1 matiz, escala 50–950 variando L (≈0.97 → 0.20) e C (pico no meio).
- **Neutros**: mesma matiz da marca com C 0.005–0.02 — "cinzas quentes/frios" que harmonizam.
- **Acento** (opcional): matiz complementar ou análoga, uso ≤ 10%.
- **Feedback**: success/warning/danger/info, sempre com texto além da cor (não depender só de cor — WCAG 1.4.1).
- **Semânticos**: `--color-bg`, `--color-surface`, `--color-surface-raised`, `--color-border`, `--color-text`, `--color-text-muted`, `--color-action`, `--color-action-hover`, `--color-on-action`, `--color-focus`.

Proporção 60-30-10 (neutro dominante, secundária, acento). Contraste: 4.5:1 texto normal, 3:1 texto ≥ 24px (ou 18.66px bold) e componentes/ícones, foco 3:1 contra o adjacente. Dark mode: não inverta — reduza croma, eleve superfícies com L maior (não sombras), texto em L ~0.93 em vez de branco puro.

## 5. Forma: raio, borda, sombra

- Raio: escala curta e coerente com a direção. Ex. sóbrio `--radius-sm: 4px; --radius-md: 8px; --radius-lg: 14px`; editorial pode ser 0–2px; amigável 10/16/24. Raio interno = raio externo − padding (raios concêntricos).
- Bordas: 1px tingida (`oklch(L C H / 0.1–0.16)`), não cinza chapado.
- Sombras em camadas (ambiente + direta), tingidas pela matiz, opacidade baixa:
  `--shadow-md: 0 1px 2px oklch(0.2 0.02 H / .06), 0 4px 12px oklch(0.2 0.02 H / .08);`
  Elevação significa algo (dropdown > card > superfície). Card estático muitas vezes não precisa de sombra.

## 6. Layout e grid

- Container: `max-width` 1200–1320px conteúdo, 72ch texto; gutter lateral fluido `clamp(16px, 4vw, 48px)`.
- Grid de 12 colunas no desktop, 6 no tablet, 4 no mobile; `gap` por token.
- Breakpoints pelo conteúdo (quando o layout quebra), tipicamente ~640/768/1024/1280. Mobile-first.
- Container queries (`@container`) para componentes que mudam conforme o espaço disponível.
- Alinhamento óptico: ícones e textos grandes às vezes precisam de 1–2px de ajuste para parecerem alinhados.
- Lei de Fitts e zona do polegar no mobile: CTA primário alcançável, sticky CTA discreto se a página for longa.

## 7. Motion

- Durações: micro (hover/press) 120–160ms; componentes (dropdown, accordion) 200–260ms; transições de página/modal 280–360ms.
- Easing: entrada `cubic-bezier(.2,.7,.2,1)` (ease-out expressivo), saída `cubic-bezier(.4,0,1,1)`, nunca `linear` em UI.
- Só `transform` e `opacity` (compositor, não afeta layout/CLS).
- `@media (prefers-reduced-motion: reduce)` → durações ~0 e sem deslocamento.
- Motion comunica: estado mudou, de onde veio, para onde foi. Se não comunica, remova.

## 8. Modelo de tokens pronto

Ajuste valores à direção escolhida; a estrutura é o que importa.

```css
:root {
  --font-display: "Fraunces", "Iowan Old Style", Georgia, serif;
  --font-body: "Inter Tight", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  --text-xs: clamp(0.75rem, 0.73rem + 0.1vw, 0.8125rem);
  --text-sm: clamp(0.875rem, 0.85rem + 0.12vw, 0.9375rem);
  --text-base: clamp(1rem, 0.97rem + 0.15vw, 1.125rem);
  --text-lg: clamp(1.25rem, 1.18rem + 0.33vw, 1.5rem);
  --text-xl: clamp(1.563rem, 1.43rem + 0.6vw, 2rem);
  --text-2xl: clamp(1.953rem, 1.7rem + 1.1vw, 2.75rem);
  --text-3xl: clamp(2.441rem, 2rem + 2vw, 3.75rem);
  --text-display: clamp(3.052rem, 2.2rem + 3.8vw, 5.5rem);

  --leading-tight: 1.05;
  --leading-snug: 1.2;
  --leading-normal: 1.55;
  --tracking-display: -0.03em;

  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;
  --space-24: 6rem;
  --space-section: clamp(4rem, 2.5rem + 6vw, 9rem);

  --hue: 155;
  --color-bg: oklch(0.985 0.006 var(--hue));
  --color-surface: oklch(0.965 0.008 var(--hue));
  --color-border: oklch(0.25 0.02 var(--hue) / 0.12);
  --color-text: oklch(0.22 0.02 var(--hue));
  --color-text-muted: oklch(0.45 0.02 var(--hue));
  --color-action: oklch(0.48 0.12 var(--hue));
  --color-action-hover: oklch(0.42 0.12 var(--hue));
  --color-on-action: oklch(0.98 0.01 var(--hue));
  --color-focus: oklch(0.6 0.16 var(--hue));

  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 14px;
  --shadow-md: 0 1px 2px oklch(0.2 0.02 var(--hue) / 0.06), 0 6px 16px oklch(0.2 0.02 var(--hue) / 0.07);

  --ease-out: cubic-bezier(0.2, 0.7, 0.2, 1);
  --duration-fast: 140ms;
  --duration-base: 220ms;

  --container: 76rem;
  --measure: 65ch;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 0.01ms !important; transition-duration: 0.01ms !important; scroll-behavior: auto !important; }
}
```
PERFECT_APP_EOF

cat > "$DEST/references/frontend-qa.md" <<'PERFECT_APP_EOF'
# Front-end, performance, acessibilidade e QA

## HTML semântico
- Landmarks: `header`, `nav`, `main` (um), `footer`, `section` com heading, `aside`.
- Um `h1` por página; headings em ordem sem pular níveis.
- `button` para ações, `a` para navegação. Nunca `div onClick`.
- Listas como `ul/ol`, tabelas como `table` com `th scope`.
- `lang="pt-BR"` no `html`.
- Skip link "Pular para o conteúdo" como primeiro elemento focável.

## Performance — Core Web Vitals (p75, mobile)
| Métrica | Bom | Ruim |
|---|---|---|
| LCP | ≤ 2,5s | > 4s |
| INP | ≤ 200ms | > 500ms |
| CLS | ≤ 0,1 | > 0,25 |

**LCP**: imagem do hero em AVIF/WebP com `srcset`/`sizes`, `fetchpriority="high"`, sem `loading="lazy"`; preload da fonte do hero; CSS crítico inline ou pequeno; evitar hero renderizado só no cliente; TTFB baixo (SSG/SSR + CDN).

**INP**: menos JS; dividir bundle (dynamic import), adiar scripts de terceiros (`defer`, carregar após interação ou com `requestIdleCallback`), handlers curtos, `content-visibility: auto` em seções longas, evitar re-render global.

**CLS**: `width`/`height` ou `aspect-ratio` em toda mídia/iframe/embed; espaço reservado para banners e skeletons com tamanho final; fontes com fallback ajustado (`size-adjust`) ou `next/font`; animar só transform/opacity.

**Outros**: imagens abaixo da dobra `loading="lazy" decoding="async"`; ícones como SVG sprite ou componente tree-shaken; remover dependências mortas; `preconnect` só para origens críticas; cache imutável para assets com hash.

## Acessibilidade — WCAG 2.2 AA
- **Contraste** (1.4.3/1.4.11): 4.5:1 texto, 3:1 texto grande e componentes de UI/ícones informativos.
- **Alvo** (2.5.8): ≥ 24×24 CSS px ou espaçamento equivalente; mire 44×44 em toque.
- **Foco visível** (2.4.7) e **não obscurecido** (2.4.11): `:focus-visible` com outline ≥ 2px e contraste 3:1; `scroll-padding-top` igual à altura do header fixo; banners de cookie/chat não cobrem o foco.
- **Teclado**: tudo operável, ordem lógica, sem armadilha de foco; modais com focus trap e `Esc`; retorno do foco ao fechar.
- **Arrastar** (2.5.7): alternativa de clique para sliders/carrosséis de arrastar.
- **Ajuda consistente** (3.2.6) e **sem entrada redundante** (3.3.7): contato no mesmo lugar em todas as páginas; não pedir o mesmo dado duas vezes.
- **Autenticação acessível** (3.3.8): permitir colar senha, gerenciadores de senha, sem quebra-cabeça cognitivo.
- **Imagens**: `alt` descritivo; decorativas com `alt=""`.
- **Formulários**: `label` associado, erros com `aria-describedby` e `aria-invalid`, não só cor.
- **Motion**: `prefers-reduced-motion`; nada piscando > 3x/s.
- **Reflow**: 320px de largura sem scroll horizontal; zoom 200% sem perda.
- ARIA só quando o HTML nativo não resolve.

## Responsivo
Teste em 320, 375, 414, 768, 1024, 1280, 1440, 1920. Verifique: quebra de headlines, imagens recortadas, tabelas (scroll contido ou reflow para cards), menus, toque vs hover (`@media (hover: hover)`), safe areas (`env(safe-area-inset-*)`), `100dvh` em vez de `100vh` no mobile.

## QA — checklist antes de entregar
- [ ] Build, lint, typecheck e testes verdes (rodar de verdade).
- [ ] Console sem erros/warnings em runtime; sem 404 de assets.
- [ ] Todos os links funcionam; âncoras rolam para o lugar certo com offset do header.
- [ ] Formulários: válido, inválido, vazio, envio duplo (botão desabilita/loading), erro de rede.
- [ ] Estados: hover, focus, active, disabled, loading, vazio, erro.
- [ ] Conteúdo extremo: nomes longos, textos 2× maiores, acentos e emojis do usuário.
- [ ] Dark mode (se existir) com contraste verificado.
- [ ] Favicon, `apple-touch-icon`, `manifest`, `theme-color`, 404 personalizada.
- [ ] Lighthouse (se disponível) ≥ 90 em Performance, A11y, Best Practices, SEO no mobile — e ainda assim validar com dados de campo depois.
- [ ] Navegador: ver a página de verdade nos breakpoints; screenshot antes/depois quando possível.
PERFECT_APP_EOF

cat > "$DEST/references/humanize-code.md" <<'PERFECT_APP_EOF'
# Humanização do código e llms.txt

Meta: o repositório deve parecer escrito por um time humano experiente — enxuto, com nomes do domínio, sem narração e sem artefatos de processo de agente. Clean code não é sinal de IA; o que denuncia é verbosidade uniforme, comentários que narram o óbvio e nomes genéricos inflados.

## 1. Naming

Sinais de IA → como um humano escreveria:

| IA | Humano |
|---|---|
| `handleButtonClickEvent`, `handleOnClick` | `submit`, `openMenu`, `handleSubmit` (o `handle` só em props de evento) |
| `userDataObject`, `responseDataArray`, `itemsList` | `user`, `orders`, `items` |
| `isUserLoggedInStatus`, `isLoadingState` | `isLoggedIn`, `loading` |
| `processData`, `handleData`, `manageItems` | verbo do domínio: `calculateTotal`, `groupByCategory` |
| `HeroSectionComponent`, `FeatureCardItemComponent` | `Hero`, `FeatureCard` |
| `UserManager`, `DataHandler`, `ServiceHelper` | o que faz: `sessionStore`, `parsePrice` |
| `utils.ts`/`helpers.ts` gigante | módulos por assunto: `format.ts`, `currency.ts` |
| `enhancedFetch`, `optimizedImage`, `improvedButton`, `newHeader`, `HeaderV2Final` | `fetchJson`, `Image`, `Button`, `Header` |
| `.hero-section-container-wrapper`, `.feature-card-item` | `.hero`, `.feature` (BEM curto: `.feature__title`) |
| `MAX_NUMBER_OF_RETRY_ATTEMPTS_ALLOWED` | `MAX_RETRIES` |
| `const result = ...; return result;` | `return ...` |
| `temp`, `data2`, `myVariable`, `foo`, `example` | nome real |

Regras:
- Convenção da linguagem/framework: camelCase (vars/funções JS/TS), PascalCase (componentes/tipos), kebab-case (arquivos de rota e classes CSS), UPPER_SNAKE só para constantes de módulo verdadeiras.
- Vocabulário do negócio do cliente (ex. `appointment`, `quote`, `plan`), em inglês.
- Comprimento proporcional ao escopo: `i` num loop curto é humano; `currentIterationIndex` não.
- Booleanos com `is/has/can/should` só quando ajuda a leitura.
- Abreviações comuns são humanas: `btn`, `nav`, `idx`, `props`, `ref`, `ctx`, `env`, `cfg` — use com moderação e consistência.
- Renomeie com ferramenta de rename (LSP, `ts-morph`, IDE) ou busca exaustiva incluindo strings em testes, stories e CSS. Depois: typecheck + build.

## 2. Comentários

Remova: comentários que narram o código (`// Initialize state`, `// Map over items`, `// Return the result`), banners de seção (`// ===== HEADER =====`), linguagem "we/nós/vamos", explicações didáticas, alternativas comentadas, `// TODO: implement` de scaffolding, JSDoc redundante que só repete a assinatura, `{/* Hero Section */}` em JSX, `<!-- Navigation -->` em HTML, `/* Button styles */` em CSS.

Preserve (o `strip_ai_traces.py` já protege):
- Shebang `#!`, `"use client"`/`"use server"`/`"use strict"` (são strings, não comentários).
- Licenças: `/*! … */`, `@license`, `@preserve`, cabeçalhos de copyright.
- Diretivas: `eslint-disable*`, `@ts-expect-error`, `@ts-ignore`, `@ts-nocheck`, `prettier-ignore`, `biome-ignore`, `istanbul ignore`, `c8 ignore`, `webpackChunkName`/`webpackPrefetch`/`@vite-ignore`, `@jsx`/`@jsxImportSource`, `# noqa`, `# type:`, `# pragma`, `# -*- coding`, `stylelint-disable`, `@tailwind`/`@apply` (não são comentários, só referência), `<!--[if IE]>`, `<!-- htmlmin:ignore -->`.
- JSDoc em projetos JS puro que dependem de `@type`/`@typedef`/`@param {Tipo}` para checagem (o script mantém blocos com tags de tipo).

Fluxo: `python3 scripts/strip_ai_traces.py <dir>` (dry-run, mostra contagem por arquivo e vestígios) → revisar → `--apply` → build/typecheck/testes. Use `--exclude` para pastas extras. `node_modules`, `.git`, `dist`, `.next`, `build`, `.claude`, `vendor` e similares já são ignorados.

Se um comentário for realmente necessário (um "porquê" não óbvio — workaround de bug de browser, regra de negócio estranha), reescreva-o curto, no tom de um dev, sem ponto final formal: `// safari ignora gap em flex antigo`. Raros e pontuais.

## 3. Vestígios de processo de IA

Candidatos a remoção (listados pelo script; apagar só com confirmação do usuário):
- `plan.md`, `PLAN.md`, `implementation_plan.md`, `IMPLEMENTATION*.md`, `progress.md`, `PROGRESS.md`, `TODO_AI.md`, `CHANGES_SUMMARY.md`, `SUMMARY.md` de agente, `NOTES_AI.md`, `scratch*.md`, `task*.md` de agente, `.aider*`, `*.orig`, `*.bak`, `*.rej`, `npm-debug.log`, `*.log` soltos.
- Rodapés/strings: "Generated with Claude Code", "🤖 Generated", "Created by AI", "Co-Authored-By: Claude" em arquivos (não reescreva histórico git sem pedido explícito), badges "Built with v0/Lovable/Bolt", `<meta name="generator" content="...">` de ferramenta.
- `console.log`/`print` de debug, `debugger;`, dados mock esquecidos em produção, títulos default ("Vite + React", "Create Next App"), favicons default (vite.svg, next.svg), README boilerplate do template.

**Sempre preservar**: `.claude/` inteira, `CLAUDE.md`, `AGENTS.md`, `Agent.md`/`agent.md`, `.cursor/rules` se o usuário usa, `.github/`, `LICENSE`, `README.md` (reescrever em tom humano se for boilerplate: o que é, como rodar, deploy, variáveis), `CHANGELOG.md` mantido por humanos, `docs/` do produto.

## 4. Estrutura e estilo
- Arquivos pequenos e coesos; sem componentes de 600 linhas nem 40 arquivos de 5 linhas.
- Imports ordenados, sem não usados; formatação pelo formatter do projeto (prettier/biome) — rode-o no fim.
- Sem abstrações especulativas (factories e generics para um caso só).
- Tratamento de erro onde importa (rede, formulário), não try/catch em volta de tudo com `console.error("An error occurred:", error)`.
- Commits (se o usuário pedir para commitar): mensagens curtas no imperativo, sem emoji nem rodapé de ferramenta, agrupadas por assunto ("redesign hero and pricing", "add security headers").

## 5. llms.txt

Padrão proposto em llmstxt.org (Jeremy Howard, 2024): arquivo Markdown na raiz do domínio (`/llms.txt`) que dá a agentes e LLMs um resumo curado do site. O Lighthouse já verifica sua presença. Não é um sitemap — seja curado (as 10–50 páginas mais úteis).

Formato:
```markdown
# Nome do site ou empresa

> Resumo de 1–3 frases: o que é, para quem, onde atua, diferencial.

Parágrafo opcional com contexto essencial (área de atendimento, horários, como contratar).

## Serviços
- [Nome do serviço](https://dominio.com/servico): Uma linha do que é e para quem.

## Empresa
- [Sobre](https://dominio.com/sobre): História, equipe e credenciais.
- [Contato](https://dominio.com/contato): Telefone, WhatsApp, endereço.

## Optional
- [Blog](https://dominio.com/blog): Artigos sobre o tema.
```
- H1 obrigatório; blockquote logo abaixo; seções H2 com listas `- [título](url): descrição`.
- `## Optional` para o que pode ser ignorado quando o contexto for curto.
- URLs absolutas e canônicas; se houver versões `.md` das páginas, linke-as.
- Local: `public/llms.txt` (Next, Vite, Astro, Nuxt, SvelteKit `static/`), ou raiz do output estático.
- Opcional: `llms-full.txt` com o conteúdo completo concatenado das páginas principais (bom para docs).
- Gere com `scripts/generate_llms_txt.py <dir> --site-url https://dominio --name "Nome" --summary "..."`, depois revise descrições à mão — elas precisam soar humanas e específicas.
- Confira que `robots.txt` não bloqueia o arquivo.
PERFECT_APP_EOF

cat > "$DEST/references/security.md" <<'PERFECT_APP_EOF'
# Segurança (front-end e borda)

Objetivo: reduzir superfície de ataque com o que está no escopo de um site/app web. Não prometa "100% seguro" no relatório.

## Security headers (base OWASP Secure Headers Project)

| Header | Valor recomendado | Protege contra |
|---|---|---|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` (comece com `max-age=31536000` sem preload se o domínio ainda não é 100% HTTPS) | Downgrade, SSL stripping |
| `Content-Security-Policy` | ver abaixo | XSS, injeção |
| `X-Content-Type-Options` | `nosniff` | MIME sniffing |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Vazamento de URL |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()` (libere só o usado) | Acesso indevido a APIs |
| `Cross-Origin-Opener-Policy` | `same-origin` | Ataques cross-window |
| `Cross-Origin-Resource-Policy` | `same-site` (ou `same-origin`) | Embedding indevido |
| `X-Frame-Options` | `DENY` (legado; o moderno é `frame-ancestors` na CSP) | Clickjacking |

`COEP: require-corp` quebra embeds de terceiros (YouTube, mapas) — use só se precisar de cross-origin isolation.

### CSP
Comece restritiva e libere por origem, nunca com `*`:
```
default-src 'self';
script-src 'self' 'nonce-{NONCE}' 'strict-dynamic';
style-src 'self' 'unsafe-inline';
img-src 'self' data: https:;
font-src 'self';
connect-src 'self' https://api.dominio.com;
frame-src https://www.youtube-nocookie.com https://www.google.com;
frame-ancestors 'none';
base-uri 'self';
form-action 'self';
object-src 'none';
upgrade-insecure-requests
```
- Em SSR (Next.js middleware, etc.) gere nonce por requisição. Em site estático, use hashes (`'sha256-…'`) para scripts inline ou elimine scripts inline.
- `style-src 'unsafe-inline'` é aceitável na maioria dos sites (risco menor que script); remova se viável.
- Analytics/pixels: liste origens exatas (`https://www.googletagmanager.com`, `https://www.google-analytics.com`, `https://connect.facebook.net`).
- Lance primeiro como `Content-Security-Policy-Report-Only` se houver risco de quebrar terceiros, e avise o usuário.

### Onde configurar
- **Vercel**: `vercel.json` → `headers: [{ source: "/(.*)", headers: [...] }]`; ou `next.config` `headers()`; nonce via `middleware.ts`.
- **Netlify / Cloudflare Pages**: arquivo `_headers` em `public/`.
- **Nginx**: `add_header ... always;` no bloco `server`.
- **Apache**: `.htaccess` com `Header always set`.
- **Firebase Hosting**: `firebase.json` → `hosting.headers`.
- **GitHub Pages**: não permite headers; use `<meta http-equiv="Content-Security-Policy">` (sem `frame-ancestors`, que não funciona em meta) e avise a limitação.

## Segredos e configuração
- Nada de chave privada no bundle. Variáveis com prefixo público (`NEXT_PUBLIC_`, `VITE_`, `PUBLIC_`, `REACT_APP_`) são visíveis a qualquer visitante.
- `.env*` no `.gitignore`; crie `.env.example` sem valores.
- Procure no código: `sk_live`, `AKIA`, `AIza`, `ghp_`, `-----BEGIN`, `password=`, tokens hardcoded. Se achar segredo já commitado, avise o usuário para **rotacionar** (remover do código não basta).
- Source maps de produção desabilitados ou não públicos.

## Formulários e entradas
- Validação no servidor sempre (cliente é só UX). Schemas (zod/valibot/yup) compartilhados.
- Anti-spam sem atrito: honeypot + tempo mínimo de preenchimento + rate limit por IP; Turnstile/hCaptcha se necessário.
- Proteção CSRF em endpoints de mutação com cookie de sessão (SameSite=Lax/Strict + token).
- Cookies: `Secure; HttpOnly; SameSite=Lax`.
- Upload: validar tipo/tamanho no servidor, nunca servir do mesmo domínio sem `Content-Disposition`.
- E-mail/WhatsApp: escapar dados do usuário em templates.

## Código do cliente
- Sem `eval`, `new Function`, `innerHTML` com dado do usuário. `dangerouslySetInnerHTML`/`v-html` só com DOMPurify.
- Links externos com `target="_blank"` → `rel="noopener noreferrer"`.
- Scripts de terceiros com SRI (`integrity` + `crossorigin`) quando servidos de CDN com versão fixa.
- iframes de terceiros com `sandbox` e `loading="lazy"` quando possível; YouTube via `youtube-nocookie.com`.
- Redirecionamentos só para destinos em allowlist (evitar open redirect).

## Dependências
- `npm audit --omit=dev` / `pnpm audit` / `yarn npm audit`; atualizar o que for seguro sem quebrar (patch/minor). Major: listar para o usuário decidir.
- Remover pacotes não usados (`depcheck`/`knip`).
- Lockfile commitado.

## Privacidade (LGPD)
- Banner de consentimento antes de cookies não essenciais/pixels, com opção de recusar tão fácil quanto aceitar.
- Política de privacidade linkada no rodapé e no formulário.
- Fontes auto-hospedadas (evita enviar IP ao Google Fonts).
- `/.well-known/security.txt` com contato (RFC 9116) — opcional, mas profissional.

---

# Checklist de segurança (obrigatório na Fase 8)

Percorra item a item. Para cada um, marque: ✅ feito, ➖ não se aplica (diga por quê), ⏳ depende do usuário (domínio, painel, DNS, provedor). Itens ⏳ entram no relatório final como pendências. Não marque ✅ sem ter verificado no código, na config ou no navegador.

## 1. Transporte (HTTPS)
- [ ] Site inteiro em HTTPS, certificado válido com renovação automática.
- [ ] Redirect 301 HTTP → HTTPS (inclusive `www` e sem `www`).
- [ ] TLS 1.2+ apenas (1.0/1.1 desativados).
- [ ] Nenhum *mixed content* (imagem, script, iframe, fonte via `http://`).
- [ ] HSTS: `Strict-Transport-Security: max-age=31536000; includeSubDomains` (`preload` só com todos os subdomínios em HTTPS).

## 2. Security headers
- [ ] CSP restritiva: `default-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; upgrade-insecure-requests`.
- [ ] CSP sem `'unsafe-eval'`, sem `*`, sem `'unsafe-inline'` em `script-src` (nonce ou hash).
- [ ] Origens de terceiros (analytics, pixel, mapas, vídeo) liberadas uma a uma.
- [ ] CSP testada em `Report-Only` antes, se houver risco de quebrar terceiros.
- [ ] `X-Content-Type-Options: nosniff`.
- [ ] `Referrer-Policy: strict-origin-when-cross-origin`.
- [ ] `Permissions-Policy` desligando câmera, microfone, geolocalização, pagamento, USB (salvo uso real).
- [ ] `Cross-Origin-Opener-Policy: same-origin`.
- [ ] `Cross-Origin-Resource-Policy: same-site`.
- [ ] `X-Frame-Options: DENY` (reforço legado).
- [ ] Remover headers que revelam tecnologia: `X-Powered-By`, versão no `Server` (ex. `poweredByHeader: false` no Next).
- [ ] Meta de nota A/A+ no securityheaders.com.

## 3. Segredos e configuração
- [ ] Nenhuma chave privada no bundle; variáveis `NEXT_PUBLIC_`/`VITE_`/`PUBLIC_`/`REACT_APP_` são públicas.
- [ ] Busca por `sk_live`, `AKIA`, `AIza`, `ghp_`, `-----BEGIN PRIVATE KEY`, senhas/tokens hardcoded (o `scan_ai_tells.py` aponta os mais comuns).
- [ ] `.env*` no `.gitignore` + `.env.example` sem valores.
- [ ] Segredo que já foi para o git → avisar para **rotacionar** (apagar não basta, fica no histórico).
- [ ] Source maps de produção desativados ou não públicos.
- [ ] Chaves públicas (Maps, Firebase etc.) restritas por domínio no painel do provedor.
- [ ] Nenhum arquivo sensível acessível por URL: `.git/`, `.env`, backups, `*.sql`, `*.log`, `phpinfo`.

## 4. XSS e injeção no front-end
- [ ] Sem `eval`, `new Function`, `setTimeout`/`setInterval` com string.
- [ ] Sem `innerHTML`/`dangerouslySetInnerHTML`/`v-html` com dado do usuário — se inevitável, DOMPurify.
- [ ] Dados do usuário escapados em HTML, atributos, URLs e JSON embutido (`<script>` com JSON: escapar `</`).
- [ ] URLs vindas do usuário validadas (bloquear `javascript:` e `data:` em `href`/redirects).
- [ ] Redirects só para destinos em allowlist (sem *open redirect*).
- [ ] Markdown/rich text renderizado com sanitização.
- [ ] Trusted Types considerado em apps grandes.

## 5. Formulários e entradas
- [ ] Validação no servidor sempre (cliente é só UX).
- [ ] Limite de tamanho e tipo em todos os campos.
- [ ] Anti-spam: honeypot + tempo mínimo de preenchimento + rate limit por IP (Turnstile/hCaptcha se necessário).
- [ ] CSRF nos endpoints que alteram dados (token + cookie `SameSite`).
- [ ] Mensagens de erro que não revelam se usuário/e-mail existe.
- [ ] Dados escapados em e-mails, templates e integrações (WhatsApp, CRM).
- [ ] Upload: tipo verificado pelo conteúdo (não só extensão), tamanho máximo, nome renomeado, armazenado fora da raiz pública ou servido com `Content-Disposition: attachment`.

## 6. Autenticação e sessão (se houver login)
- [ ] Cookies de sessão `Secure; HttpOnly; SameSite=Lax/Strict`.
- [ ] Token de sessão nunca em `localStorage`/`sessionStorage`.
- [ ] Limite de tentativas de login com bloqueio progressivo.
- [ ] Senhas: mínimo de 8 caracteres, checagem contra senhas vazadas, permitir colar e gerenciadores (WCAG 3.3.8).
- [ ] MFA disponível, pelo menos para admins.
- [ ] Logout invalida a sessão no servidor.
- [ ] Recuperação de senha com token de uso único e expiração curta.
- [ ] Autorização verificada no servidor em cada requisição (esconder botão não é controle de acesso).
- [ ] IDs de recursos não previsíveis ou com checagem de dono (sem IDOR).

## 7. APIs e comunicação
- [ ] CORS restrito a origens conhecidas; nunca `*` com credenciais.
- [ ] Rate limiting nos endpoints públicos.
- [ ] Erros sem stack trace nem detalhes internos.
- [ ] Endpoints de admin/debug fora de produção ou protegidos.
- [ ] Webhooks validados por assinatura.

## 8. Terceiros e dependências
- [ ] `npm audit --omit=dev` (ou pnpm/yarn) sem vulnerabilidades altas/críticas.
- [ ] Dependências não usadas removidas (`knip`/`depcheck`); lockfile commitado.
- [ ] Atualizações automáticas (Dependabot/Renovate) sugeridas ao usuário.
- [ ] Scripts de CDN com versão fixa + SRI (`integrity` + `crossorigin`).
- [ ] `target="_blank"` sempre com `rel="noopener noreferrer"`.
- [ ] Iframes de terceiros com `sandbox` quando possível; YouTube via `youtube-nocookie.com`.
- [ ] Inventário de scripts de terceiros; remover os não usados.

## 9. Privacidade (LGPD)
- [ ] Consentimento antes de cookies não essenciais/pixels; "Recusar" tão fácil quanto "Aceitar".
- [ ] Política de privacidade e termos no rodapé e nos formulários.
- [ ] Coleta mínima de dados para a finalidade.
- [ ] Fontes auto-hospedadas (sem enviar IP ao Google Fonts sem consentimento).
- [ ] Nenhum dado pessoal em URLs, query strings ou eventos de analytics.
- [ ] Canal para o titular exercer direitos (e-mail do encarregado/DPO).

## 10. Infraestrutura e borda
- [ ] CDN/WAF na frente (Cloudflare, Vercel, AWS) com proteção DDoS básica.
- [ ] DNS com DNSSEC (se o provedor suportar) e registros CAA.
- [ ] E-mail do domínio com SPF, DKIM e DMARC.
- [ ] Staging/preview com `noindex` e, de preferência, protegidos por senha.
- [ ] `/.well-known/security.txt` com contato (RFC 9116).
- [ ] Backups e plano de rollback do deploy.

## 11. Verificação final
- [ ] securityheaders.com → A/A+.
- [ ] SSL Labs (ssllabs.com/ssltest) → A/A+.
- [ ] Mozilla Observatory → B+ ou maior.
- [ ] Lighthouse Best Practices sem alertas de segurança.
- [ ] Console do navegador sem violações de CSP nem mixed content.
- [ ] Teste manual: colar `<script>alert(1)</script>` e `"><img src=x onerror=alert(1)>` nos campos; acessar `/.env` e `/.git/config`; enviar o formulário várias vezes seguidas; trocar o ID na URL para tentar abrir recurso de outro usuário.
- [ ] Varredura automatizada (OWASP ZAP baseline) em apps com login ou API própria.

Os itens das seções 1, 10 e 11 que exigem domínio em produção normalmente ficam ⏳ — entregue ao usuário a lista exata do que testar após o deploy. Para sistemas com dados sensíveis ou pagamentos, recomende pentest profissional periódico.
PERFECT_APP_EOF

cat > "$DEST/references/seo.md" <<'PERFECT_APP_EOF'
# SEO técnico e on-page

## Metadados por página
- `<title>`: ≤ 60 caracteres, palavra-chave principal no início, marca no fim ("Contabilidade para clínicas em BH | Nome").
- `<meta name="description">`: 120–155 caracteres, benefício + CTA implícito. Única por página.
- `<link rel="canonical">` absoluto.
- `<meta name="viewport" content="width=device-width, initial-scale=1">` (sem `maximum-scale`/`user-scalable=no` — fere acessibilidade).
- `<html lang="pt-BR">`; `hreflang` se multi-idioma.
- `robots` meta só quando precisar de `noindex` (páginas de obrigado, staging).
- Remover `<meta name="generator">` de ferramentas.

## Open Graph / Twitter
`og:title`, `og:description`, `og:image` (1200×630, < 300KB, texto legível), `og:url`, `og:type`, `og:locale=pt_BR`, `og:site_name`, `twitter:card=summary_large_image`.

## Dados estruturados (JSON-LD)
Escolha pelo tipo de negócio, só com dados verdadeiros:
- `Organization` (logo, sameAs das redes, contactPoint) — quase sempre.
- `LocalBusiness` (ou subtipo: `Dentist`, `LegalService`, `Restaurant`…) com `address`, `geo`, `openingHoursSpecification`, `telephone`, `priceRange` — negócio físico.
- `Product` + `Offer` (+ `AggregateRating` só se houver avaliações reais) — e-commerce.
- `FAQPage` — se houver FAQ visível na página.
- `BreadcrumbList` — páginas internas.
- `WebSite` com `potentialAction` SearchAction — se houver busca.
Valide no Rich Results Test depois do deploy.

## Arquivos de rastreamento
- `robots.txt` com `Sitemap: https://dominio/sitemap.xml`. Não bloqueie CSS/JS. Decida com o usuário a política para crawlers de IA (GPTBot, ClaudeBot, Google-Extended, PerplexityBot) — padrão: permitir, já que ele quer `llms.txt`.
- `sitemap.xml` com URLs canônicas e `lastmod` real. Em Next.js use `app/sitemap.ts`; Astro `@astrojs/sitemap`.
- `llms.txt` na raiz (ver humanize-code.md).

## On-page
- Um `h1` com a intenção principal; `h2` como subtópicos que respondem perguntas reais.
- Conteúdo útil acima da dobra renderizado no HTML (SSR/SSG), não só via JS.
- Links internos com texto âncora descritivo (não "clique aqui").
- Imagens: nome de arquivo descritivo, `alt` útil, formatos modernos.
- URLs curtas, minúsculas, com hífen, sem parâmetros desnecessários.
- Performance e mobile (Core Web Vitals) entram no ranking como desempate — ver frontend-qa.md.
- SEO local (se aplicável): NAP (nome, endereço, telefone) idêntico ao Google Business Profile, mapa embutido com lazy load, página por cidade/serviço só se houver conteúdo próprio.

## GEO (otimização para respostas de IA)
Conteúdo factual e citável: definições claras, números com fonte, FAQ direta, autor/empresa identificados (E-E-A-T), dados estruturados. `llms.txt` ajuda agentes a navegar, mas não é garantia de citação.
PERFECT_APP_EOF

cat > "$DEST/scripts/generate_llms_txt.py" <<'PERFECT_APP_EOF'
#!/usr/bin/env python3
"""Generate an llms.txt (llmstxt.org format) from built HTML or from framework routes."""
import argparse
import html
import os
import re
from html.parser import HTMLParser
from pathlib import Path

BUILD_DIRS = ["out", "dist", "build", ".output/public", "_site", "public", "www", "."]
SKIP_DIRS = {"node_modules", ".git", ".claude", "assets", "_next", "static", "_astro", "fonts", "img", "images"}

SECTION_RULES = [
    ("services", r"^(servicos|serviços|services|solucoes|soluções|solutions|tratamentos|especialidades)"),
    ("products", r"^(produtos|products|loja|shop|store|planos|pricing|precos|preços)"),
    ("docs", r"^(docs|documentacao|documentação|guides|guias|ajuda|help)"),
    ("company", r"^(sobre|about|empresa|company|equipe|team|contato|contact|carreiras|careers|depoimentos|cases|portfolio)"),
    ("optional", r"^(blog|posts|artigos|articles|news|noticias|notícias|privacidade|privacy|termos|terms|cookies|legal|lgpd)"),
]
SECTION_TITLES = {
    "pt": {"main": "Páginas principais", "services": "Serviços", "products": "Produtos e planos", "docs": "Documentação",
           "company": "Empresa", "other": "Outras páginas", "optional": "Optional"},
    "en": {"main": "Main pages", "services": "Services", "products": "Products and pricing", "docs": "Docs",
           "company": "Company", "other": "Other pages", "optional": "Optional"},
}


class MetaParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.title, self.description, self.canonical, self.h1 = "", "", "", ""
        self.robots = ""
        self._in = None

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "title":
            self._in = "title"
        elif tag == "h1" and not self.h1:
            self._in = "h1"
        elif tag == "meta":
            name = (a.get("name") or a.get("property") or "").lower()
            if name in ("description", "og:description") and not self.description:
                self.description = a.get("content", "")
            if name == "robots":
                self.robots = a.get("content", "").lower()
        elif tag == "link" and (a.get("rel") or "").lower() == "canonical":
            self.canonical = a.get("href", "")

    def handle_endtag(self, tag):
        if tag in ("title", "h1"):
            self._in = None

    def handle_data(self, data):
        if self._in == "title":
            self.title += data
        elif self._in == "h1":
            self.h1 += data


def clean(s):
    return re.sub(r"\s+", " ", html.unescape(s or "")).strip()


def from_html(root, site_url):
    pages = []
    for base in BUILD_DIRS:
        d = root / base
        if not d.is_dir():
            continue
        found = []
        for dirpath, dirnames, filenames in os.walk(d):
            dirnames[:] = [x for x in dirnames if x not in SKIP_DIRS and not (base == "." and x in {"src", "app", "pages"})]
            for f in filenames:
                if not f.endswith(".html") or f.startswith(("404", "500", "_")):
                    continue
                p = Path(dirpath) / f
                rel = p.relative_to(d).as_posix()
                route = "/" + re.sub(r"(^|/)index\.html$", "", rel)
                route = re.sub(r"\.html$", "", route)
                mp = MetaParser()
                try:
                    mp.feed(p.read_text(encoding="utf-8", errors="ignore"))
                except Exception:
                    continue
                if "noindex" in mp.robots:
                    continue
                url = mp.canonical if mp.canonical.startswith("http") else site_url.rstrip("/") + (route if route != "/" else "/")
                found.append({"route": route, "url": url, "title": clean(mp.title) or clean(mp.h1), "description": clean(mp.description)})
        if found:
            pages = found
            break
    return pages


ROUTE_GLOBS = [
    ("app", r"page\.(tsx|jsx|ts|js|mdx|md)$", "next-app"),
    ("src/app", r"page\.(tsx|jsx|ts|js|mdx|md)$", "next-app"),
    ("pages", r"\.(tsx|jsx|ts|js|vue|mdx|md)$", "pages"),
    ("src/pages", r"\.(tsx|jsx|ts|js|astro|vue|mdx|md)$", "pages"),
    ("src/routes", r"\+page\.svelte$", "sveltekit"),
]


def route_from(rel, kind):
    parts = rel.split("/")
    if kind in ("next-app", "sveltekit"):
        parts = parts[:-1]
    else:
        last = re.sub(r"\.\w+$", "", parts[-1])
        parts = parts[:-1] + ([] if last == "index" else [last])
    parts = [p for p in parts if not (p.startswith("(") and p.endswith(")")) and not p.startswith("@")]
    if any(p.startswith(("[", "_")) or p in ("api",) for p in parts):
        return None
    return "/" + "/".join(parts)


def from_routes(root, site_url):
    pages = []
    for base, pattern, kind in ROUTE_GLOBS:
        d = root / base
        if not d.is_dir():
            continue
        for dirpath, dirnames, filenames in os.walk(d):
            dirnames[:] = [x for x in dirnames if x not in {"node_modules", "api", "components"}]
            for f in filenames:
                if not re.search(pattern, f) or f.startswith(("_app", "_document", "_error", "404", "500")):
                    continue
                p = Path(dirpath) / f
                route = route_from(p.relative_to(d).as_posix(), kind)
                if route is None:
                    continue
                text = p.read_text(encoding="utf-8", errors="ignore")
                title = re.search(r"title\s*[:=]\s*[\"'`]([^\"'`]{3,120})[\"'`]", text)
                desc = re.search(r"description\s*[:=]\s*[\"'`]([^\"'`]{10,300})[\"'`]", text)
                pages.append({"route": route, "url": site_url.rstrip("/") + (route if route != "/" else "/"),
                              "title": clean(title.group(1)) if title else "", "description": clean(desc.group(1)) if desc else ""})
        if pages:
            break
    return pages


def section_of(route):
    first = route.strip("/").split("/")[0].lower()
    if not first:
        return "main"
    for key, pattern in SECTION_RULES:
        if re.match(pattern, first):
            return key
    return "other"


def title_from_route(route):
    seg = route.strip("/").split("/")[-1] or "home"
    return seg.replace("-", " ").replace("_", " ").capitalize()


def build(pages, name, summary, details, lang):
    titles = SECTION_TITLES[lang]
    seen, groups = set(), {}
    for p in sorted(pages, key=lambda x: (x["route"].count("/"), x["route"])):
        if p["url"] in seen:
            continue
        seen.add(p["url"])
        groups.setdefault(section_of(p["route"]), []).append(p)
    home = next((p for p in pages if p["route"] == "/"), None)
    name = name or (home and home["title"].split("|")[0].split(" - ")[0].strip()) or "Site"
    summary = summary or (home and home["description"]) or "TODO: one or two sentences about what this site offers and for whom."
    lines = [f"# {name}", "", f"> {summary}", ""]
    if details:
        lines += [details, ""]
    for key in ["main", "services", "products", "docs", "company", "other", "optional"]:
        items = groups.get(key)
        if not items:
            continue
        lines.append(f"## {titles[key]}")
        for p in items[:50]:
            label = (p["title"].split("|")[0].strip() if p["title"] else "") or title_from_route(p["route"])
            desc = p["description"] or "TODO: describe this page in one line"
            lines.append(f"- [{label}]({p['url']}): {desc}")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def default_out(root):
    for d in ("public", "static"):
        if (root / d).is_dir():
            return root / d / "llms.txt"
    return root / "llms.txt"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("root")
    ap.add_argument("--site-url", required=True, help="https://your-domain.com")
    ap.add_argument("--name")
    ap.add_argument("--summary")
    ap.add_argument("--details", help="optional paragraph after the summary")
    ap.add_argument("--lang", choices=["pt", "en"], default="pt")
    ap.add_argument("--out")
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--print", dest="print_only", action="store_true")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    pages = from_html(root, args.site_url) or from_routes(root, args.site_url)
    if not pages:
        pages = [{"route": "/", "url": args.site_url.rstrip("/") + "/", "title": args.name or "", "description": args.summary or ""}]
    content = build(pages, args.name, args.summary, args.details, args.lang)
    if args.print_only:
        print(content)
        return
    out = Path(args.out) if args.out else default_out(root)
    if out.exists() and not args.force:
        print(f"{out} already exists; use --force to overwrite. Generated content:\n")
        print(content)
        return
    out.write_text(content, encoding="utf-8")
    todo = content.count("TODO")
    print(f"wrote {out} ({len(pages)} pages){' — fill ' + str(todo) + ' TODO descriptions' if todo else ''}")


if __name__ == "__main__":
    main()
PERFECT_APP_EOF

cat > "$DEST/scripts/js_comments.mjs" <<'PERFECT_APP_EOF'
import { createRequire } from "node:module";
import { readFileSync } from "node:fs";

const [, , parserDir, kind] = process.argv;
const require = createRequire(parserDir.endsWith("/") ? parserDir : parserDir + "/");
const { parse } = require("@babel/parser");

const input = JSON.parse(readFileSync(0, "utf8"));

function pluginsFor(variant) {
  const common = ["decorators-legacy", "importAttributes", "explicitResourceManagement", "doExpressions", "exportDefaultFrom"];
  if (variant === "ts") return ["typescript", ...common];
  if (variant === "tsx") return ["typescript", "jsx", ...common];
  return ["jsx", ...common];
}

const results = input.map(({ code, variant }) => {
  try {
    const ast = parse(code, {
      sourceType: "unambiguous",
      allowReturnOutsideFunction: true,
      allowImportExportEverywhere: true,
      allowAwaitOutsideFunction: true,
      allowSuperOutsideMethod: true,
      allowUndeclaredExports: true,
      errorRecovery: false,
      plugins: pluginsFor(variant),
    });
    return {
      ok: true,
      comments: (ast.comments || []).map((c) => ({ type: c.type, start: c.start, end: c.end, value: c.value })),
    };
  } catch (err) {
    return { ok: false, error: String(err.message || err) };
  }
});

process.stdout.write(JSON.stringify(results));
PERFECT_APP_EOF

cat > "$DEST/scripts/scan_ai_tells.py" <<'PERFECT_APP_EOF'
#!/usr/bin/env python3
"""Scan a web project for visual, copy and code patterns typical of AI-generated UIs."""
import argparse
import colorsys
import json
import os
import re
from pathlib import Path

SKIP_DIRS = {
    "node_modules", ".git", ".claude", "dist", "build", "out", ".next", ".nuxt", ".output", ".svelte-kit",
    ".vercel", ".netlify", ".turbo", ".cache", "coverage", "vendor", "__pycache__", ".venv", "venv", ".astro",
    "storybook-static",
}
MARKUP_EXT = {".html", ".htm", ".jsx", ".tsx", ".vue", ".svelte", ".astro", ".mdx"}
STYLE_EXT = {".css", ".scss", ".sass", ".less", ".pcss"}
SCRIPT_EXT = {".js", ".ts", ".mjs", ".cjs", ".jsx", ".tsx", ".vue", ".svelte", ".astro"}
CONFIG_NAMES = {"tailwind.config.js", "tailwind.config.ts", "tailwind.config.cjs", "tailwind.config.mjs"}

EMOJI_RE = re.compile("[\U0001F300-\U0001FAFF\U00002600-\U000027BF\U0001F000-\U0001F2FF]")
BUZZ = [
    "unlock", "elevate", "seamless", "seamlessly", "effortless", "revolutionize", "revolutionary", "supercharge",
    "empower", "leverage", "cutting-edge", "game-changer", "game changer", "next-level", "next level",
    "all-in-one", "build the future", "scale without limits", "in today's", "unleash", "transform your",
    "take your .{1,20} to the next level", "desbloqueie", "eleve", "revolucione", "potencialize", "solução completa",
    "no mundo de hoje", "transforme sua", "leve seu .{1,20} ao próximo nível", "sem esforço", "de forma fluida",
]
BUZZ_RE = re.compile(r"\b(" + "|".join(BUZZ) + r")\b", re.I)
PLACEHOLDER_RE = re.compile(
    r"lorem ipsum|john doe|jane (doe|smith)|\bacme\b|company name|your company|sua empresa aqui|"
    r"\(555\)|555-\d{4}|example\.com|fulano de tal|\b(10x|99\.9%|10,?000\+)", re.I)
DEFAULT_TITLE_RE = re.compile(r"<title>\s*(vite \+ \w+|create next app|react app|my app|document|untitled)\s*</title>|"
                              r"title:\s*[\"'](create next app|my app)[\"']|vite\.svg|next\.svg", re.I)
TW_PURPLE_GRAD_RE = re.compile(r"\bfrom-(purple|violet|indigo|fuchsia)-\d{2,3}\b[^\"'`]*\b(via|to)-(blue|indigo|purple|violet|pink|cyan|fuchsia)-\d{2,3}", re.I)
TW_PURPLE_RE = re.compile(r"\b(bg|text|border|ring|from|to|via|shadow)-(indigo|violet|purple)-\d{2,3}\b")
GRAD_TEXT_RE = re.compile(r"bg-clip-text|background-clip:\s*text|-webkit-text-fill-color:\s*transparent", re.I)
GLASS_RE = re.compile(r"backdrop-blur|backdrop-filter", re.I)
BLOB_RE = re.compile(r"blur-(2xl|3xl)|blur-\[\d{2,}px\]|filter:\s*blur\(\s*[4-9]\d|filter:\s*blur\(\s*\d{3}|aurora|blob", re.I)
ROUNDED_RE = re.compile(r"\brounded-(2xl|3xl)\b")
SHADOW_RE = re.compile(r"\bshadow-(lg|xl|2xl)\b")
THREE_COL_RE = re.compile(r"\b(md:|lg:|sm:)?grid-cols-3\b|repeat\(\s*3\s*,\s*(1fr|minmax)", re.I)
CENTER_RE = re.compile(r"\btext-center\b|text-align:\s*center")
PING_RE = re.compile(r"animate-ping|animate-pulse")
FADE_RE = re.compile(r"whileInView|initial=\{\{\s*opacity:\s*0|data-aos=|fade-?in-?up|animate-fade", re.I)
LINEAR_GRAD_RE = re.compile(r"linear-gradient\(([^;]+)\)", re.I)
HEX_RE = re.compile(r"#([0-9a-f]{6}|[0-9a-f]{3})\b", re.I)
FONT_RE = re.compile(r"font-family:\s*([^;}{]+)|from\s+[\"']next/font/google[\"'];?\s*|import\s*\{([^}]+)\}\s*from\s*[\"']next/font/google|"
                     r"fonts\.googleapis\.com/css2?\?family=([^\"'&]+)|fontFamily:\s*\{([^}]+)\}", re.I)
GENERIC_FONTS = ["inter", "roboto", "arial", "open sans", "open_sans", "poppins", "montserrat", "helvetica", "system-ui", "segoe ui", "lato"]

NARRATE_RE = re.compile(r"^\s*(//|#|\*|/\*)\s*(initialize|initialise|create|define|set up|setup|handle|render|return|import|main|helper|"
                        r"this (function|component|hook)|we |now |first,|here we|step \d|todo: implement|add |update |check if|loop through)", re.I | re.M)
BANNER_RE = re.compile(r"(//|/\*|#|<!--)\s*[=\-*#]{4,}|\{/\*\s*[\w ]+(section|component)\s*\*/\}", re.I)
JSX_SECTION_RE = re.compile(r"\{/\*.*?\*/\}|<!--.*?-->", re.S)
COMMENT_LINE_RE = re.compile(r"^\s*(//|/\*|\*|#(?!!)|<!--)", re.M)
NAME_TELLS = [
    (r"\bhandle\w+Event\b", "handleXEvent"),
    (r"\b[a-z]\w*(DataObject|DataArray|ObjectData|ListArray|InfoObject)\b", "verbose data suffix"),
    (r"\b(function|const|class)\s+\w+Component\b", "Component suffix"),
    (r"\b(enhanced|optimized|improved|new|better|custom|my)[A-Z]\w*\b", "enhanced/optimized prefix"),
    (r"\b\w+(Final|V2|Copy|Old|Backup)\b", "Final/V2 suffix"),
    (r"\b\w+(Manager|Handler|Helper)\b", "Manager/Handler/Helper"),
    (r"\bis\w+(Status|State|Flag)\b", "isXStatus"),
    (r"className=[\"'][^\"']*\b[\w]+-(section-container|container-wrapper|card-item|item-wrapper|wrapper-container)\b", "inflated CSS class"),
]
NAME_RES = [(re.compile(p), label) for p, label in NAME_TELLS]
AI_FILES_RE = re.compile(r"^(plan|implementation[_-]?plan|progress|changes?[_-]?summary|ai[_-][\w-]*|todo[_-]ai)\.md$", re.I)


def hue_of(hexstr):
    h = hexstr.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    return hh * 360, ss


def purple_blue_gradient(args):
    hues = [hue_of(m.group(0)) for m in HEX_RE.finditer(args)]
    vivid = [h for h, s in hues if s > 0.35]
    if not vivid:
        return bool(re.search(r"purple|violet|indigo|fuchsia", args, re.I))
    return any(250 <= h <= 320 for h in vivid) and any(190 <= h <= 330 for h in vivid)


class Scanner:
    def __init__(self, root):
        self.root = root
        self.hits = {}
        self.fonts = set()
        self.stats = {"code_lines": 0, "comment_lines": 0}
        self.files = set()

    def add(self, key, rel, line, snippet):
        bucket = self.hits.setdefault(key, [])
        bucket.append(f"{rel}:{line}: {snippet.strip()[:90]}")

    def scan_regex(self, key, regex, text, rel, max_hits=200):
        for m in regex.finditer(text):
            line = text.count("\n", 0, m.start()) + 1
            self.add(key, rel, line, m.group(0))

    def visible_text(self, text, ext):
        if ext in {".html", ".htm"}:
            text = re.sub(r"<(script|style)\b.*?</\1>", " ", text, flags=re.S | re.I)
        return text

    def scan_file(self, path):
        rel = str(path.relative_to(self.root))
        ext = path.suffix.lower()
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            return
        if ".min." in path.name:
            return
        self.files.add(rel)
        is_markup = ext in MARKUP_EXT
        is_style = ext in STYLE_EXT or path.name in CONFIG_NAMES
        if is_markup or is_style or ext in SCRIPT_EXT:
            self.scan_regex("purple_gradient_tailwind", TW_PURPLE_GRAD_RE, text, rel)
            self.scan_regex("purple_indigo_classes", TW_PURPLE_RE, text, rel)
            self.scan_regex("gradient_text", GRAD_TEXT_RE, text, rel)
            self.scan_regex("glassmorphism", GLASS_RE, text, rel)
            self.scan_regex("blur_blobs", BLOB_RE, text, rel)
            self.scan_regex("rounded_2xl_3xl", ROUNDED_RE, text, rel)
            self.scan_regex("heavy_shadows", SHADOW_RE, text, rel)
            self.scan_regex("three_equal_columns", THREE_COL_RE, text, rel)
            self.scan_regex("centered_text", CENTER_RE, text, rel)
            self.scan_regex("pulse_ping_dots", PING_RE, text, rel)
            self.scan_regex("scroll_fade_animations", FADE_RE, text, rel)
            for m in LINEAR_GRAD_RE.finditer(text):
                if purple_blue_gradient(m.group(1)):
                    self.add("purple_blue_css_gradient", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in FONT_RE.finditer(text):
                chunk = " ".join(g for g in m.groups() if g) or m.group(0)
                for name in re.findall(r"[A-Za-z][A-Za-z_ \-]+", chunk):
                    clean = name.strip().strip("_").lower().replace("_", " ")
                    if clean and clean not in {"sans-serif", "serif", "monospace", "var", "font", "next", "google", "from", "import", "family", "display", "swap", "wght", "ital"}:
                        self.fonts.add(clean)
        if is_markup:
            vis = self.visible_text(text, ext)
            for m in EMOJI_RE.finditer(vis):
                line_no = vis.count("\n", 0, m.start()) + 1
                self.add("emoji_in_ui", rel, line_no, vis[max(0, m.start() - 30):m.end() + 30].replace("\n", " "))
            self.scan_regex("buzzword_copy", BUZZ_RE, vis, rel)
            self.scan_regex("placeholder_content", PLACEHOLDER_RE, vis, rel)
            self.scan_regex("default_titles_icons", DEFAULT_TITLE_RE, text, rel)
            for m in re.finditer(r"<(button|a)\b[^>]*>\s*(submit|get started|learn more|saiba mais|click here|clique aqui|enviar)\s*<", text, re.I):
                self.add("generic_cta_labels", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"target=[\"']_blank[\"'](?![^>]*rel=)", text):
                self.add("blank_without_noopener", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"<img\b(?![^>]*\balt=)[^>]*>", text, re.I):
                self.add("img_without_alt", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"<(script|img|iframe|link|source|video|audio)\b[^>]*\b(src|href)=[\"']http://(?!localhost|127\.0\.0\.1)", text, re.I):
                self.add("mixed_content", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"<script\b(?![^>]*\bintegrity=)[^>]*\bsrc=[\"']https://(cdn\.|unpkg\.com|cdnjs\.|code\.jquery)[^\"']*[\"'][^>]*>", text, re.I):
                self.add("cdn_script_without_sri", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"<iframe\b(?![^>]*\bsandbox)[^>]*>", text, re.I):
                self.add("iframe_without_sandbox", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"href=\{?[\"'`]?javascript:", text, re.I):
                self.add("javascript_href", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"<div[^>]+onClick=", text):
                self.add("div_onclick", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
        if ext in SCRIPT_EXT or ext in STYLE_EXT or ext in {".html", ".htm", ".py"}:
            lines = text.splitlines()
            self.stats["code_lines"] += sum(1 for l in lines if l.strip())
            self.stats["comment_lines"] += len(COMMENT_LINE_RE.findall(text)) + len(JSX_SECTION_RE.findall(text))
            self.scan_regex("narrating_comments", NARRATE_RE, text, rel)
            self.scan_regex("section_banners", BANNER_RE, text, rel)
            for regex, label in NAME_RES:
                for m in regex.finditer(text):
                    self.add("ai_style_names", rel, text.count("\n", 0, m.start()) + 1, f"[{label}] {m.group(0)}")
            for m in re.finditer(r"^\s*(console\.(log|debug)\(|debugger\b)", text, re.M):
                self.add("debug_statements", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"dangerouslySetInnerHTML|v-html=|\binnerHTML\s*=|\beval\(|new Function\(", text):
                self.add("unsafe_html_or_eval", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"(localStorage|sessionStorage)\.setItem\(\s*[\"'`][^\"'`]*(token|jwt|session|auth)", text, re.I):
                self.add("token_in_web_storage", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"setTimeout\(\s*[\"'`]|setInterval\(\s*[\"'`]", text):
                self.add("unsafe_html_or_eval", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"Access-Control-Allow-Origin[\"']?\s*[,:]\s*[\"']\*|origin:\s*[\"']\*[\"']", text):
                self.add("wildcard_cors", rel, text.count("\n", 0, m.start()) + 1, m.group(0))
            for m in re.finditer(r"(sk_live_|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z\-_]{35}|ghp_[A-Za-z0-9]{36}|-----BEGIN (RSA |EC )?PRIVATE KEY)", text):
                self.add("possible_secrets", rel, text.count("\n", 0, m.start()) + 1, m.group(0)[:12] + "…")
        if AI_FILES_RE.match(path.name):
            self.add("ai_process_files", rel, 1, path.name)
        if re.search(r"Generated (with|by) \[?(Claude|ChatGPT|Copilot|Cursor|v0|Lovable|Bolt)|🤖 Generated", text):
            self.add("ai_generated_footer", rel, 1, "generated-with mention")

    def project_checks(self):
        missing = []
        names = {Path(f).name.lower() for f in self.files}
        all_files = set()
        for dirpath, dirnames, filenames in os.walk(self.root):
            dirnames[:] = [d for d in dirnames if d not in {"node_modules", ".git"}]
            for f in filenames:
                all_files.add(f.lower())
        if "llms.txt" not in all_files:
            missing.append("llms.txt")
        if "robots.txt" not in all_files and not any(n.startswith("robots.") for n in names):
            missing.append("robots.txt (or app/robots.ts)")
        if not any(n.startswith("sitemap") for n in all_files):
            missing.append("sitemap.xml (or app/sitemap.ts)")
        header_files = {"_headers", "vercel.json", "netlify.toml", "firebase.json", "nginx.conf", ".htaccess", "middleware.ts", "middleware.js", "staticwebapp.config.json"}
        header_hit = False
        for f in self.files:
            p = self.root / f
            if p.name in header_files or p.name.startswith("next.config"):
                try:
                    if re.search(r"Content-Security-Policy|Strict-Transport-Security", p.read_text(encoding="utf-8"), re.I):
                        header_hit = True
                except OSError:
                    pass
        if not header_hit:
            missing.append("security headers (CSP/HSTS) config")
        if "security.txt" not in all_files:
            missing.append("/.well-known/security.txt")
        gitignore = self.root / ".gitignore"
        try:
            if not re.search(r"^\s*\.env", gitignore.read_text(encoding="utf-8"), re.M):
                missing.append(".env not in .gitignore")
        except OSError:
            missing.append(".gitignore (with .env)")
        env_files = [f for f in all_files if f.startswith(".env") and f not in {".env.example", ".env.sample", ".env.template"}]
        if env_files:
            missing.append(f"real env files present ({', '.join(sorted(env_files))}) — confirm they are not committed")
        for f in self.files:
            if Path(f).name.startswith("next.config"):
                try:
                    if "poweredByHeader" not in (self.root / f).read_text(encoding="utf-8"):
                        missing.append("next.config: poweredByHeader: false")
                except OSError:
                    pass
        joined = ""
        for f in self.files:
            if f.endswith((".html", ".tsx", ".jsx", ".astro", ".vue", ".svelte", ".ts", ".js")):
                try:
                    joined += (self.root / f).read_text(encoding="utf-8")[:20000]
                except OSError:
                    pass
        if not re.search(r"<html[^>]+lang=|lang:\s*[\"']|htmlAttrs", joined):
            missing.append("<html lang>")
        if not re.search(r"name=[\"']description[\"']|description:\s*[\"'`]", joined):
            missing.append("meta description")
        if not re.search(r"og:image|openGraph", joined):
            missing.append("Open Graph tags")
        if not re.search(r"application/ld\+json|jsonLd|json-ld", joined, re.I):
            missing.append("JSON-LD structured data")
        if not re.search(r"prefers-reduced-motion|motion-reduce|useReducedMotion", joined + self._styles()):
            missing.append("prefers-reduced-motion handling")
        if not re.search(r"focus-visible", joined + self._styles()):
            missing.append(":focus-visible styles")
        return missing

    def _styles(self):
        out = ""
        for f in self.files:
            if Path(f).suffix.lower() in STYLE_EXT:
                try:
                    out += (self.root / f).read_text(encoding="utf-8")[:50000]
                except OSError:
                    pass
        return out


WEIGHTS = {
    "purple_gradient_tailwind": 3, "purple_blue_css_gradient": 3, "gradient_text": 3, "emoji_in_ui": 3,
    "blur_blobs": 2, "glassmorphism": 2, "placeholder_content": 3, "buzzword_copy": 2, "default_titles_icons": 2,
    "purple_indigo_classes": 2, "rounded_2xl_3xl": 1, "heavy_shadows": 1, "three_equal_columns": 1,
    "centered_text": 1, "pulse_ping_dots": 1, "scroll_fade_animations": 1, "generic_cta_labels": 1,
    "narrating_comments": 2, "section_banners": 2, "ai_style_names": 2, "debug_statements": 1,
    "ai_process_files": 3, "ai_generated_footer": 3, "generic_display_font": 2,
    "token_in_web_storage": 3, "wildcard_cors": 2, "mixed_content": 2, "cdn_script_without_sri": 1,
    "iframe_without_sandbox": 1, "javascript_href": 2,
    "blank_without_noopener": 1, "img_without_alt": 1, "div_onclick": 1, "unsafe_html_or_eval": 2, "possible_secrets": 3,
}

LABELS = {
    "purple_gradient_tailwind": "Purple/indigo→blue gradients (Tailwind)",
    "purple_blue_css_gradient": "Purple→blue CSS gradients",
    "purple_indigo_classes": "Indigo/violet/purple utility colors",
    "gradient_text": "Gradient text",
    "glassmorphism": "Glassmorphism / backdrop blur",
    "blur_blobs": "Blurred blobs / auroras",
    "rounded_2xl_3xl": "rounded-2xl/3xl everywhere",
    "heavy_shadows": "Heavy generic shadows",
    "three_equal_columns": "3 equal columns grids",
    "centered_text": "Centered text everywhere",
    "pulse_ping_dots": "Pulse/ping dots",
    "scroll_fade_animations": "Fade-in-on-scroll animations",
    "emoji_in_ui": "Emoji used as UI icons/copy",
    "buzzword_copy": "Buzzword copy",
    "placeholder_content": "Placeholder / invented content",
    "default_titles_icons": "Default template title/icons",
    "generic_cta_labels": "Generic CTA labels",
    "blank_without_noopener": "target=_blank without rel",
    "img_without_alt": "<img> without alt",
    "div_onclick": "div with onClick (should be button/a)",
    "narrating_comments": "Narrating comments",
    "section_banners": "Section banner comments",
    "ai_style_names": "AI-style identifiers",
    "debug_statements": "console.log / debugger",
    "unsafe_html_or_eval": "Unsafe HTML injection / eval",
    "possible_secrets": "Possible secrets in source",
    "token_in_web_storage": "Auth token stored in localStorage/sessionStorage",
    "wildcard_cors": "Wildcard CORS (*)",
    "mixed_content": "Mixed content (http:// resources)",
    "cdn_script_without_sri": "CDN script without SRI integrity",
    "iframe_without_sandbox": "iframe without sandbox",
    "javascript_href": "javascript: in href",
    "ai_process_files": "AI process files (plan.md…)",
    "ai_generated_footer": "'Generated with AI' mentions",
    "generic_display_font": "Only generic fonts detected",
}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("root")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--examples", type=int, default=4)
    args = ap.parse_args()
    root = Path(args.root).resolve()
    sc = Scanner(root)
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            sc.scan_file(Path(dirpath) / name)
    if sc.fonts and all(any(g in f for g in GENERIC_FONTS) for f in sc.fonts):
        sc.add("generic_display_font", ".", 0, ", ".join(sorted(sc.fonts)))
    missing = sc.project_checks()
    ratio = sc.stats["comment_lines"] / max(1, sc.stats["code_lines"])
    score = sum(WEIGHTS.get(k, 1) * min(3, 1 + len(v) // 5) for k, v in sc.hits.items())
    if ratio > 0.12:
        score += 3
    score += len(missing)
    level = "low" if score < 10 else "medium" if score < 25 else "high"

    if args.json:
        print(json.dumps({"score": score, "level": level, "comment_ratio": round(ratio, 3), "fonts": sorted(sc.fonts),
                          "hits": {k: {"count": len(v), "examples": v[:args.examples]} for k, v in sc.hits.items()},
                          "missing": missing}, ensure_ascii=False, indent=2))
        return
    print(f"# AI-tells scan — {root}")
    print(f"\nScore: {score} ({level} AI-look). Comment ratio: {ratio:.1%}. Fonts: {', '.join(sorted(sc.fonts)) or 'none detected'}")
    order = sorted(sc.hits.items(), key=lambda kv: -WEIGHTS.get(kv[0], 1) * len(kv[1]))
    print("\n## Findings")
    if not order:
        print("- none")
    for key, items in order:
        print(f"\n### {LABELS.get(key, key)} — {len(items)}")
        for ex in items[:args.examples]:
            print(f"- {ex}")
    print("\n## Missing professional basics")
    for m in missing or ["none"]:
        print(f"- {m}")


if __name__ == "__main__":
    main()
PERFECT_APP_EOF

cat > "$DEST/scripts/strip_ai_traces.py" <<'PERFECT_APP_EOF'
#!/usr/bin/env python3
"""Strip comments and list AI-process leftovers in a web project.

Dry-run by default. Use --apply to rewrite files without comments and
--delete-traces to delete the high-confidence leftover files.
"""
import argparse
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tokenize
from pathlib import Path

SKIP_DIRS = {
    "node_modules", ".git", ".claude", ".github", ".cursor", ".vscode", ".idea",
    "dist", "build", "out", ".next", ".nuxt", ".output", ".svelte-kit", ".vercel",
    ".netlify", ".turbo", ".cache", ".parcel-cache", "coverage", "vendor",
    "__pycache__", ".venv", "venv", "env", ".astro", "storybook-static", ".expo",
}

JS_EXT = {".js": "js", ".jsx": "js", ".mjs": "js", ".cjs": "js", ".ts": "ts", ".mts": "ts", ".cts": "ts", ".tsx": "tsx"}
CSS_EXT = {".css", ".scss", ".sass", ".less", ".pcss", ".postcss"}
HTML_EXT = {".html", ".htm"}
SFC_EXT = {".vue", ".svelte", ".astro"}
PY_EXT = {".py"}

KEEP_RE = re.compile(
    r"@license|@preserve|@copyright|\bcopyright\b|\(c\)\s*\d{4}|eslint-|@ts-|prettier-ignore|biome-ignore|"
    r"istanbul ignore|c8 ignore|v8 ignore|webpack[A-Z]|@vite-ignore|@jsx|#__PURE__|@__PURE__|"
    r"#__NO_SIDE_EFFECTS__|@refresh|^\s*globals?\s+\w|jshint|sourceMappingURL|sourceURL|@flow|@noflow|@format|"
    r"tslint:|deno-lint-ignore|deno-fmt-ignore|oxlint-|svelte-ignore|@vue-ignore|<reference|stylelint-|"
    r"postcss-|purgecss|htmlmin:|@vitest-environment|@jest-environment|@ts-check|@ts-nocheck|turbopack",
    re.IGNORECASE,
)
JSDOC_TYPE_RE = re.compile(r"@(type|typedef|template|satisfies|import|callback|param\s*\{|returns?\s*\{|property\s*\{|enum)\b")
PY_KEEP_RE = re.compile(r"noqa|type:\s*ignore|type:|pragma|pylint:|fmt:\s*(off|on|skip)|isort:|mypy:|pyright:|ruff:|-\*-\s*coding", re.I)

PROTECTED_NAMES = {
    "claude.md", "agents.md", "agent.md", "gemini.md", ".cursorrules", ".windsurfrules", "license", "license.md",
    "license.txt", "readme.md", "readme", "changelog.md", "contributing.md", "security.md", "code_of_conduct.md",
    "llms.txt", "llms-full.txt",
}

TRACE_REMOVE = [
    r"plan\.md", r"implementation[_-]?plan\.md", r"implementation[_-]?(notes|summary|details|steps)?\.md",
    r"progress\.md", r"changes?[_-]?summary\.md", r"refactor[_-]?(plan|summary|notes)\.md", r"ai[_-][\w-]*\.md",
    r"[\w-]*[_-]ai\.md", r"todo[_-]ai\.md", r"agent[_-](notes|log|plan|output)\.md", r"scratch(pad)?[\w-]*\.(md|txt)",
    r"prompts?\.(md|txt)", r"\.aider[\w.-]*", r"[\w.-]+\.(orig|rej|bak|swp)", r"npm-debug\.log[\w.-]*",
    r"yarn-(debug|error)\.log[\w.-]*", r"pnpm-debug\.log[\w.-]*", r"\.ds_store", r"thumbs\.db",
]
TRACE_REVIEW = [
    r"todo\.md", r"notes\.md", r"summary\.md", r"tasks?\.md", r"spec\.md", r"design[_-]?notes\.md",
    r"architecture\.md", r"roadmap\.md", r"[\w.-]+\.log", r"report\.md", r"analysis\.md", r"checklist\.md",
]
TRACE_REMOVE_RE = re.compile(r"^(" + "|".join(TRACE_REMOVE) + r")$", re.I)
TRACE_REVIEW_RE = re.compile(r"^(" + "|".join(TRACE_REVIEW) + r")$", re.I)

CONTENT_TRACE_RE = re.compile(
    r"Generated (with|by) \[?(Claude|ChatGPT|GPT|Copilot|Cursor|v0|Lovable|Bolt|Gemini|Windsurf)|"
    r"🤖\s*Generated|Co-Authored-By:\s*(Claude|Copilot|Cursor)|Created (with|by) (AI|an AI)|"
    r"<meta[^>]+name=[\"']generator[\"'][^>]+(v0|lovable|bolt|framer ai|webflow ai|wix ai)|"
    r"Built with (v0|Lovable|Bolt\.new)|As an AI|I'?ve (implemented|created|added) (the|a|this)",
    re.I,
)
DEBUG_RE = re.compile(r"^\s*(console\.(log|debug|table|dir)\(|debugger;?\s*$|print\(\s*[\"']debug)", re.M)


def find_parser_dir():
    cache = Path(os.environ.get("PERFECT_APP_CACHE", Path.home() / ".cache" / "perfect-app"))
    if (cache / "node_modules" / "@babel" / "parser").exists():
        return cache
    if not shutil.which("node") or not shutil.which("npm"):
        return None
    cache.mkdir(parents=True, exist_ok=True)
    print("installing @babel/parser into", cache, file=sys.stderr)
    res = subprocess.run(
        ["npm", "install", "--prefix", str(cache), "--no-audit", "--no-fund", "--silent", "@babel/parser@7"],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        print(res.stderr, file=sys.stderr)
        return None
    return cache


def utf16_to_py_index(text):
    if all(ord(ch) < 0x10000 for ch in text):
        return None
    mapping = []
    for i, ch in enumerate(text):
        mapping.append(i)
        if ord(ch) >= 0x10000:
            mapping.append(i)
    mapping.append(len(text))
    return mapping


def js_comment_ranges(snippets, parser_dir):
    script = Path(__file__).with_name("js_comments.mjs")
    res = subprocess.run(
        ["node", str(script), str(parser_dir), "batch"],
        input=json.dumps(snippets), capture_output=True, text=True,
    )
    if res.returncode != 0:
        raise RuntimeError(res.stderr.strip())
    return json.loads(res.stdout)


def should_keep_js(comment, variant, is_first):
    value = comment["value"]
    raw_start = "/*" if comment["type"] == "CommentBlock" else "//"
    if raw_start == "/*" and value.startswith("!"):
        return True
    if raw_start == "//" and value.startswith("/") and "<reference" in value:
        return True
    if KEEP_RE.search(value):
        return True
    if variant == "js" and raw_start == "/*" and value.startswith("*") and JSDOC_TYPE_RE.search(value):
        return True
    return False


def removal_span(text, start, end, jsx_braces=True):
    if jsx_braces:
        i = start - 1
        while i >= 0 and text[i] in " \t\r\n":
            i -= 1
        j = end
        while j < len(text) and text[j] in " \t\r\n":
            j += 1
        if i >= 0 and text[i] == "{" and j < len(text) and text[j] == "}":
            start, end = i, j + 1
    line_start = text.rfind("\n", 0, start) + 1
    line_end = text.find("\n", end)
    if line_end == -1:
        line_end = len(text)
    before = text[line_start:start]
    after = text[end:line_end]
    if before.strip() == "" and after.strip() == "":
        return line_start, min(line_end + 1, len(text))
    if after.strip() == "":
        k = start
        while k > line_start and text[k - 1] in " \t":
            k -= 1
        return k, end
    if before.strip() == "":
        k = end
        while k < line_end and text[k] in " \t":
            k += 1
        return start, k
    k = end
    while k < line_end and text[k] in " \t":
        k += 1
    if start > line_start and text[start - 1] in " \t":
        if k < line_end and text[k] in ")]},;":
            b = start
            while b > line_start and text[b - 1] in " \t":
                b -= 1
            return b, k
        return start, k
    return start, end


def apply_spans(text, spans):
    if not spans:
        return text
    spans = sorted(spans)
    merged = [list(spans[0])]
    for s, e in spans[1:]:
        if s <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], e)
        else:
            merged.append([s, e])
    out, pos = [], 0
    for s, e in merged:
        out.append(text[pos:s])
        pos = e
    out.append(text[pos:])
    result = "".join(out)
    return re.sub(r"\n[ \t]*\n([ \t]*\n)+", "\n\n", result)


def css_comment_spans(text, line_comments):
    spans, i, n = [], 0, len(text)
    quote = None
    while i < n:
        ch = text[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue
        if ch in "\"'":
            quote = ch
            i += 1
            continue
        if text.startswith("url(", i):
            close = text.find(")", i)
            i = n if close == -1 else close + 1
            continue
        if text.startswith("/*", i):
            close = text.find("*/", i + 2)
            close = n if close == -1 else close + 2
            body = text[i + 2:close - 2]
            if not body.startswith("!") and not KEEP_RE.search(body):
                spans.append(removal_span(text, i, close, jsx_braces=False))
            i = close
            continue
        if line_comments and text.startswith("//", i) and (i == 0 or text[i - 1] != ":"):
            close = text.find("\n", i)
            close = n if close == -1 else close
            body = text[i + 2:close]
            if not KEEP_RE.search(body):
                spans.append(removal_span(text, i, close, jsx_braces=False))
            i = close
            continue
        i += 1
    return spans


def html_comment_spans(text, offset_text=None):
    spans = []
    for m in re.finditer(r"<!--(.*?)-->", text, re.S):
        body = m.group(1)
        if body.startswith("[if") or body.startswith("<![endif]") or body.startswith("!") or KEEP_RE.search(body):
            continue
        spans.append(removal_span(text, m.start(), m.end(), jsx_braces=False))
    return spans


def protected_regions(text):
    regions = []
    for m in re.finditer(r"<(pre|textarea|code)\b[^>]*>.*?</\1>", text, re.S | re.I):
        regions.append((m.start(), m.end()))
    return regions


def inside(regions, pos):
    return any(s <= pos < e for s, e in regions)


def py_strip(text):
    spans = []
    try:
        tokens = list(tokenize.generate_tokens(io.StringIO(text).readline))
    except (tokenize.TokenError, SyntaxError, IndentationError):
        return None
    line_offsets = [0]
    for line in text.splitlines(keepends=True):
        line_offsets.append(line_offsets[-1] + len(line))
    for tok in tokens:
        if tok.type != tokenize.COMMENT:
            continue
        (srow, scol), (erow, ecol) = tok.start, tok.end
        if srow == 1 and tok.string.startswith("#!"):
            continue
        if srow <= 2 and "coding" in tok.string:
            continue
        if PY_KEEP_RE.search(tok.string) or KEEP_RE.search(tok.string):
            continue
        start = line_offsets[srow - 1] + scol
        end = line_offsets[erow - 1] + ecol
        spans.append(removal_span(text, start, end, jsx_braces=False))
    return spans


class Stripper:
    def __init__(self, parser_dir):
        self.parser_dir = parser_dir
        self.errors = []

    def js_spans(self, items):
        if not items:
            return []
        if not self.parser_dir:
            raise RuntimeError("node/npm not available; JS/TS comments not processed")
        results = js_comment_ranges([{"code": c, "variant": v} for c, v in items], self.parser_dir)
        out = []
        for (code, variant), res in zip(items, results):
            if not res["ok"]:
                out.append(None)
                self.errors.append(res["error"])
                continue
            mapping = utf16_to_py_index(code)
            spans = []
            for idx, c in enumerate(res["comments"]):
                if should_keep_js(c, variant, idx == 0):
                    continue
                s, e = c["start"], c["end"]
                if mapping:
                    s, e = mapping[s], mapping[e]
                spans.append(removal_span(code, s, e))
            out.append(spans)
        return out

    def strip_js(self, text, variant):
        spans = self.js_spans([(text, variant)])[0]
        if spans is None:
            return None, 0
        return apply_spans(text, spans), len(spans)

    def strip_css(self, text, ext):
        spans = css_comment_spans(text, line_comments=ext in {".scss", ".sass", ".less"})
        return apply_spans(text, spans), len(spans)

    def strip_blocks(self, text, sfc_kind=None):
        spans = []
        regions = protected_regions(text)
        blocks = []
        for m in re.finditer(r"<(script|style)\b([^>]*)>(.*?)</\1>", text, re.S | re.I):
            tag, attrs, body = m.group(1).lower(), m.group(2), m.group(3)
            blocks.append((m.start(3), m.end(3), tag, attrs))
        if sfc_kind == "astro":
            fm = re.match(r"\A(\s*---\r?\n)(.*?)(\r?\n---)", text, re.S)
            if fm:
                blocks.append((fm.start(2), fm.end(2), "script", 'lang="ts"'))
        js_items, js_meta = [], []
        for s, e, tag, attrs in blocks:
            body = text[s:e]
            if tag == "style":
                lang = re.search(r"lang=[\"'](\w+)", attrs)
                ext = "." + lang.group(1) if lang else ".css"
                for a, b in css_comment_spans(body, line_comments=ext in {".scss", ".sass", ".less"}):
                    spans.append((s + a, s + b))
                continue
            t = re.search(r"type=[\"']([^\"']+)", attrs)
            if t and not re.search(r"javascript|module|babel|text/jsx", t.group(1), re.I):
                continue
            if re.search(r"\bsrc=", attrs) and not body.strip():
                continue
            is_ts = bool(re.search(r"lang=[\"']ts", attrs))
            js_items.append((body, "ts" if is_ts else "js"))
            js_meta.append(s)
        for s, res in zip(js_meta, self.js_spans(js_items)):
            if res is None:
                return None, 0
            spans.extend((s + a, s + b) for a, b in res)
        block_regions = [(s, e) for s, e, *_ in blocks]
        for a, b in html_comment_spans(text):
            if not inside(block_regions, a) and not inside(regions, a):
                spans.append((a, b))
        if sfc_kind == "astro":
            for m in re.finditer(r"\{\s*/\*.*?\*/\s*\}", text, re.S):
                if not inside(block_regions, m.start()) and not KEEP_RE.search(m.group(0)):
                    spans.append(removal_span(text, m.start(), m.end(), jsx_braces=False))
        return apply_spans(text, spans), len(spans)

    def strip_file(self, path):
        text = path.read_text(encoding="utf-8")
        ext = path.suffix.lower()
        if ext in JS_EXT:
            return text, *self.strip_js(text, JS_EXT[ext])
        if ext in CSS_EXT:
            return text, *self.strip_css(text, ext)
        if ext in HTML_EXT:
            return text, *self.strip_blocks(text)
        if ext in SFC_EXT:
            return text, *self.strip_blocks(text, ext[1:])
        if ext in PY_EXT:
            spans = py_strip(text)
            if spans is None:
                return text, None, 0
            return text, apply_spans(text, spans), len(spans)
        return text, None, 0


def walk(root, extra_excludes):
    for dirpath, dirnames, filenames in os.walk(root):
        rel = Path(dirpath).relative_to(root)
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and str(rel / d) not in extra_excludes and d not in extra_excludes]
        for name in filenames:
            yield Path(dirpath) / name


def is_minified(path, text):
    if ".min." in path.name:
        return True
    lines = text.splitlines() or [""]
    return len(text) > 2000 and max(len(l) for l in lines) > 1000 and len(lines) < 20


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("root")
    ap.add_argument("--apply", action="store_true", help="rewrite files without comments")
    ap.add_argument("--delete-traces", action="store_true", help="delete high-confidence leftover files")
    ap.add_argument("--exclude", action="append", default=[], help="extra directory names/paths to skip")
    ap.add_argument("--no-python", action="store_true", help="do not touch .py files")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    stripper = Stripper(find_parser_dir())
    report = {"stripped": [], "failed": [], "remove": [], "review": [], "content_traces": [], "debug": [], "js_skipped": False}
    code_ext = set(JS_EXT) | CSS_EXT | HTML_EXT | SFC_EXT | (set() if args.no_python else PY_EXT)

    for path in walk(root, set(args.exclude)):
        rel = str(path.relative_to(root))
        lname = path.name.lower()
        if lname not in PROTECTED_NAMES:
            if TRACE_REMOVE_RE.match(lname):
                report["remove"].append(rel)
                continue
            if TRACE_REVIEW_RE.match(lname):
                report["review"].append(rel)
        ext = path.suffix.lower()
        if ext not in code_ext and ext not in {".md", ".txt", ".json"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for m in CONTENT_TRACE_RE.finditer(text):
            line = text.count("\n", 0, m.start()) + 1
            report["content_traces"].append(f"{rel}:{line}: {m.group(0)[:80]}")
        if ext not in code_ext or is_minified(path, text):
            continue
        debug_hits = len(DEBUG_RE.findall(text))
        if debug_hits:
            report["debug"].append(f"{rel}: {debug_hits}")
        try:
            original, new, count = stripper.strip_file(path)
        except RuntimeError as err:
            report["js_skipped"] = str(err)
            continue
        if new is None:
            report["failed"].append(rel)
            continue
        if count and new != original:
            report["stripped"].append({"file": rel, "comments": count})
            if args.apply:
                path.write_text(new, encoding="utf-8")

    if args.delete_traces:
        for rel in report["remove"]:
            p = root / rel
            if p.is_file():
                p.unlink()

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return

    mode = "APPLIED" if args.apply else "DRY-RUN"
    total = sum(item["comments"] for item in report["stripped"])
    print(f"# strip_ai_traces [{mode}] — {root}")
    print(f"\n## Comments: {total} in {len(report['stripped'])} files")
    for item in sorted(report["stripped"], key=lambda x: -x["comments"])[:60]:
        print(f"- {item['file']}: {item['comments']}")
    if len(report["stripped"]) > 60:
        print(f"- ... +{len(report['stripped']) - 60} files")
    if report["failed"]:
        print("\n## Could not parse (left untouched)")
        for f in report["failed"]:
            print(f"- {f}")
    if report["js_skipped"]:
        print(f"\n## JS/TS skipped: {report['js_skipped']}")
    verb = "deleted" if args.delete_traces else "to delete (confirm with user, then --delete-traces)"
    print(f"\n## Leftover files {verb}: {len(report['remove'])}")
    for f in report["remove"]:
        print(f"- {f}")
    print(f"\n## Review manually (may be human docs): {len(report['review'])}")
    for f in report["review"]:
        print(f"- {f}")
    print(f"\n## AI mentions inside files: {len(report['content_traces'])}")
    for t in report["content_traces"][:40]:
        print(f"- {t}")
    print(f"\n## Debug statements (remove by hand): {len(report['debug'])} files")
    for d in report["debug"][:40]:
        print(f"- {d}")
    print("\nProtected and never touched: .claude/, CLAUDE.md, AGENTS.md, Agent.md, README, LICENSE, .github/, llms.txt")


if __name__ == "__main__":
    main()
PERFECT_APP_EOF

chmod +x "$DEST"/scripts/*.py
echo "perfect-app instalada em $DEST — reinicie o Claude Code e use /perfect-app"
