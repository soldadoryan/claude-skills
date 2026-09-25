# Guia de escolha de modelo

Leia este arquivo quando a escolha do agente não for óbvia pela tabela do SKILL.md.

## Regra geral

Para cada etapa, responda nesta ordem:

1. **Qual qualidade esta etapa exige?** (inegociável)
2. **Qual o modelo mais barato que entrega essa qualidade com confiança?** Esse é o escolhido.

Pergunta auxiliar: **"se esta etapa sair errada, quanto custa consertar depois?"** — quanto maior esse custo, menor a margem para arriscar um modelo mais barato.

## A escala, do mais barato ao mais caro

Haiku 4.5 → Sonnet 5 → Opus 5.5 → Fable 5.1

## Sinais para subir de nível

- O pedido é vago ou tem requisitos que se contradizem
- Envolve concorrência, cache, fusos horários, dinheiro, autenticação ou permissões
- Um bug que já resistiu a uma tentativa de correção
- Mudança que afeta muitos módulos ao mesmo tempo
- Código legado sem testes

## Sinais para descer de nível

- Já existe um plano detalhado (PLAN.md) cobrindo a etapa
- A tarefa se descreve em uma frase sem "depende"
- O resultado é fácil de conferir (compila, teste passa, diff pequeno)
- É repetição do mesmo padrão em vários arquivos

## Opus 5.5 x Fable 5.1

O Fable é o modelo mais capaz disponível no Claude Code e o mais caro. Ele se destaca em sessões longas e autônomas: investiga antes de agir e verifica o próprio trabalho com frequência. Use-o apenas quando pelo menos um destes for verdade:

- o problema é grande demais para uma sessão (ex.: migração de um sistema inteiro, auditoria de arquitetura de um monorepo)
- é ambíguo a ponto de exigir investigação longa antes de qualquer decisão (causa raiz de falha intermitente em produção sem pista clara)
- o Opus 5.5 já tentou e não entregou a qualidade exigida

Em todos os outros casos de planejamento, arquitetura e depuração, o Opus 5.5 é o piso de qualidade e o Fable seria gasto sem retorno.

Quando o usuário usa `/full-strong`, esta análise é dispensada nas etapas de julgamento: o Fable é usado diretamente (ver a seção "Modo `/full-strong`" do SKILL.md).

Cuidados com o Fable:

- Em alguns planos, o uso do Fable é cobrado em créditos extras. Sinalize no plano e peça confirmação antes de escalar para ele.
- Pedidos marcados pelos classificadores de segurança (principalmente cibersegurança e biologia) são refeitos em um Opus anterior. O mesmo vale para o Opus 5.5. Nesses domínios, avise o usuário que o modelo escolhido pode não ser o que responde.
- Requer Claude Code v2.1.257 ou superior. O Opus 5.5 requer v2.1.280 ou superior.

## Nível de esforço (effort)

Fable 5.1, Opus 5.5 e Sonnet 5 aceitam os níveis `low`, `medium`, `high`, `xhigh` e `max`. O Haiku 4.5 não tem esse controle. O esforço é definido no campo `effort` do subagente.

- O Opus 5.5 começa em `medium` por padrão; os outros, em `high`.
- Para planejamento, arquitetura e revisão crítica, use `high`: são as etapas em que raciocínio raso custa mais caro depois. É por isso que o subagente `planner` já vem com `effort: high`.
- `max` pode ajudar em tarefas muito difíceis, mas tende a pensar demais e ter retorno decrescente. Só use se o nível abaixo já se mostrou insuficiente.
- Reduzir o esforço é economia legítima apenas em tarefas simples em que ele não muda o resultado. Não reduza para economizar em etapas de decisão.

## Casos de borda

- **Depuração:** Sonnet 5 se o erro tem stack trace claro; Opus 5.5 se o bug é intermitente ou "funciona na minha máquina"; Fable 5.1 se o Opus já falhou ou se a investigação atravessa muitos serviços.
- **Revisão de código:** Sonnet 5 para PRs pequenos; Opus 5.5 para mudanças de arquitetura, segurança ou quando o autor foi o próprio Sonnet em uma tarefa grande.
- **Documentação:** Haiku 4.5 para docstrings e README simples; Sonnet 5 para guias; Opus 5.5 para documentos de decisão de arquitetura (ADRs).
- **Pesquisa/leitura de muitos arquivos:** Haiku 4.5, várias instâncias em paralelo se os arquivos forem independentes.
- **Prototipagem rápida:** Sonnet 5 direto, sem planejamento, se o usuário disser que é descartável.

## Custo total, não custo por chamada

- Quando dois modelos entregam a mesma qualidade com certeza, use o mais barato. Pagar mais não compra nada.
- Quando há dúvida se o mais barato entrega a mesma qualidade, use o mais forte. O retrabalho quase sempre custa mais que a diferença de preço.
- Haiku que precisa ser refeito por Sonnet = custo dos dois, e mais tempo. Pior que Sonnet direto.
- Sonnet implementando sem plano algo complexo, seguido de correções = normalmente mais caro que Opus planejando + Sonnet implementando.
- Opus ou Fable fazendo trabalho mecânico = mesmo resultado que Haiku, várias vezes mais caro.

Os preços atuais de cada modelo aparecem no seletor `/model` do Claude Code.
