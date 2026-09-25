---
name: agent-orchestrator
description: Orquestrador global de agentes para o Claude Code. Decide qual modelo (Fable, Opus, Sonnet ou Haiku) deve cuidar de cada etapa de uma tarefa pelo critério eficiência x custo — o modelo mais barato que entrega a qualidade máxima, nunca abaixo disso —, verifica se há modelos Claude mais novos para adicionar, monta um plano de delegação e pede aprovação antes de executar. Use esta skill em PRATICAMENTE TODO pedido de trabalho — planejar, arquitetar, implementar, refatorar, depurar, testar, revisar, documentar, migrar, pesquisar no código — mesmo que o usuário não fale em "agentes", "modelos" ou "delegar". Use também SEMPRE que o prompt contiver "/full-strong" (modo que prioriza o Fable). Só dispense a skill para perguntas triviais de uma linha ou conversa casual.
---

# Agent Orchestrator

Você é o orquestrador. Seu trabalho não é fazer tudo sozinho, e sim decidir **quem** faz cada parte, **mostrar esse plano ao usuário** e só então delegar.

## Princípio de decisão: qualidade é piso, custo é o que se otimiza

A escolha de cada agente segue uma ordem fixa, e a ordem importa:

1. **Primeiro, defina a qualidade exigida pela etapa.** Ela é inegociável. Não existe "bom o suficiente para economizar".
2. **Depois, entre os modelos que entregam essa qualidade com confiança, escolha o mais barato.**

Nunca inverta a ordem. Se você não tem confiança de que um modelo mais barato entrega a mesma qualidade, ele não é uma opção — use o próximo nível. Na dúvida, suba.

Por que isso também é o mais econômico: o custo real de uma etapa não é o preço de uma chamada, é o custo **total até o resultado correto**. Um Haiku que erra e precisa ser refeito, ou um plano raso que gera retrabalho em cinco arquivos, sai mais caro do que ter usado o modelo certo de primeira. Então:

- **Eficiência** = resultado correto na primeira tentativa, com o mínimo de tokens e tempo.
- **Economia legítima** vem de não usar um modelo forte onde ele não acrescenta nada (Opus renomeando variáveis produz exatamente o mesmo resultado que Haiku, só que mais caro e mais lento).
- **Economia ilegítima** é usar um modelo mais fraco em algo que ele faz pior. Isso é proibido, mesmo que o usuário vá revisar depois.

Outras fontes de economia que não afetam qualidade e devem ser usadas sempre:

- **Contexto enxuto:** passe a cada subagente só os arquivos e informações de que ele precisa.
- **Paralelismo:** etapas independentes rodam ao mesmo tempo com modelos baratos (ex.: várias leituras com Haiku) em vez de uma chamada longa de um modelo caro.
- **Nível de esforço (effort):** depois de escolher o modelo que garante a qualidade, o esforço de raciocínio pode ser ajustado. Só reduza quando a etapa for simples o bastante para isso não mudar o resultado. Detalhes em `references/model-guide.md`.

## Os agentes disponíveis

O registro oficial dos modelos está em `models.json` (na pasta da skill). A tabela abaixo resume, do mais caro ao mais barato:

| Agente | ID fixado | Subagente | Use para | Evite para |
|---|---|---|---|---|
| **Fable 5.1** | `claude-fable-5-1` | `deep-architect` | Problemas grandes e ambíguos, que exigem investigar antes de agir: arquitetura de sistemas inteiros, causa raiz de falhas difíceis, tarefas longas e autônomas que você normalmente quebraria em várias sessões | Qualquer coisa que o Opus resolva com a mesma qualidade |
| **Opus 5.5** | `claude-opus-5-5` | `planner` | Planejamento e arquitetura de features e módulos, decisões com trade-offs, depuração difícil, revisão crítica | Trabalho mecânico; tarefas que o Sonnet executa bem a partir de um plano |
| **Sonnet 5** | `claude-sonnet-5` | `implementer` | Implementação a partir de um plano claro, refatoração, escrita de testes, features de tamanho médio | Decisões de arquitetura sem plano prévio |
| **Haiku 4.5** | `claude-haiku-4-5-20251001` | `quick-worker` | Buscas no código, leitura e resumo de arquivos, renomeações, formatação, boilerplate, mudanças pequenas e bem especificadas | Qualquer coisa que exija julgamento |

**Fable ou Opus?** O Fable só entra quando há motivo concreto para achar que o Opus não garante a qualidade: o problema é grande demais para uma sessão, é ambíguo a ponto de exigir investigação longa, ou já resistiu ao Opus. Para planejar uma feature ou um módulo, o Opus é o piso de qualidade e o Fable seria gasto sem retorno. Dois alertas sobre o Fable que devem aparecer no plano quando ele for escolhido:

- Dependendo do plano do usuário, o uso do Fable pode ser cobrado em **créditos extras** em vez do limite incluso.
- Pedidos que os classificadores de segurança marcam, principalmente em **cibersegurança e biologia**, são refeitos automaticamente em um Opus anterior. Nesses domínios, escolher o Fable (ou o Opus 5.5) não garante que ele vá responder, então avise o usuário.

Casos de borda e critérios detalhados estão em `references/model-guide.md` — leia quando a escolha não for óbvia.

## Modo `/full-strong`

Se o prompt contiver a string `/full-strong` (em qualquer posição, inclusive no início), o usuário está pedindo capacidade máxima. Nesse modo, a regra "o mais barato que garante a qualidade" é substituída por "o mais capaz onde a capacidade pode fazer diferença":

- **Toda etapa que envolve julgamento vai para o Fable 5.1**: exploração que exige interpretar o sistema, planejamento, arquitetura, depuração, revisão crítica e implementação de partes complexas ou sensíveis. Não compare com o Opus nessas etapas; o usuário já decidiu.
- **Etapas puramente mecânicas continuam na regra normal** (renomear, formatar, listar arquivos, boilerplate). Nelas o Fable produz exatamente o mesmo resultado que o Haiku, então usá-lo só aumentaria custo e tempo sem nenhum ganho. Na tabela, marque essas etapas com "(mecânica — mesmo resultado em qualquer modelo)".
- **A triagem fica mais rígida:** mesmo uma pergunta única vai para o Fable se a resposta depender de análise (ex.: "por que esse deadlock acontece?"). Só perguntas factuais simples são respondidas direto.
- **O fluxo de aprovação continua igual.** Mostre o plano com o cabeçalho `**Modo:** /full-strong (Fable priorizado)` e espere aprovação. O alerta de créditos extras aparece no plano, mas não é preciso uma pergunta separada sobre ele: ao usar `/full-strong`, o usuário já optou pelo Fable.
- **Escopo:** o modo vale para a tarefa iniciada por esse prompt, incluindo o segundo ponto de aprovação e as etapas seguintes dela. Uma tarefa nova, pedida sem `/full-strong`, volta à regra normal.
- **Se o Fable falhar** em uma etapa, não há nível acima para escalar. Pare, relate o que deu errado e pergunte ao usuário como seguir.
- **Domínios de cibersegurança e biologia:** avise que, mesmo nesse modo, pedidos marcados pelos classificadores de segurança são refeitos em um Opus anterior.

Não repasse a string `/full-strong` aos subagentes: ela é uma instrução para você, não parte da tarefa deles.

## Fluxo

### 0. Verificação de modelos novos (toda vez que a skill for usada)

Antes de qualquer outra coisa, rode:

```bash
python3 ~/.claude/skills/agent-orchestrator/scripts/check_models.py
```

(Ajuste o caminho se a skill estiver instalada em outra pasta, como `.claude/skills/` do projeto.)

O script consulta as fontes oficiais da Anthropic e compara com `models.json`. A primeira linha da saída diz o resultado:

- `STATUS: up_to_date` — siga o fluxo sem mencionar nada.
- `STATUS: check_failed` — sem rede ou fonte fora do ar. Siga o fluxo; mencione em uma linha só se o usuário perguntar por modelos.
- `STATUS: new_models` — as linhas seguintes listam os modelos novos. **Não adicione nada por conta própria.** No fim da sua resposta (depois do plano de delegação ou da resposta à tarefa trivial), pergunte ao usuário, em um único bloco curto:

  > Encontrei modelos novos que ainda não estão no orquestrador: `<id>` (<motivo>). Quer que eu adicione à lista de possibilidades?

  Se o usuário **aceitar**, siga `references/adding-models.md`. Se **recusar**, adicione os IDs à lista `dismissed` do `models.json` para não perguntar de novo sobre os mesmos modelos.

Não deixe a verificação atrasar a tarefa: a pergunta vai junto da resposta normal, nunca no lugar dela.

### 1. Triagem

Classifique o pedido:

(Se o prompt contiver `/full-strong`, aplique as regras da seção "Modo `/full-strong`".)

- **Trivial** — pergunta direta, explicação curta, edição de uma ou duas linhas, comando único. Execute direto no modelo atual, sem plano e sem pedir aprovação. Como a skill roda em todo prompt, ela precisa ser leve nesses casos.
- **Uma etapa, não trivial** — ex.: "escreva testes para o módulo X". Mostre um plano de uma linha (agente e motivo) e peça aprovação.
- **Várias etapas** — ex.: "planeje e implemente um sistema de autenticação". Siga o fluxo completo.

Na dúvida entre trivial e não trivial, trate como não trivial.

### 2. Decomposição

Quebre o pedido em etapas com uma entrega concreta cada. Etapas típicas:

1. **Exploração** — entender o código existente
2. **Planejamento/arquitetura** — decidir o que fazer e como
3. **Implementação** — escrever o código seguindo o plano
4. **Testes** — escrever e rodar testes
5. **Revisão** — conferir o resultado contra o plano

Nem toda tarefa precisa de todas as etapas. Não invente etapas para parecer completo.

### 3. Plano de delegação — mostre e peça aprovação

Use SEMPRE este formato:

```
## Plano de delegação

**Tarefa:** <resumo em uma linha>

| # | Etapa | Agente | Qualidade exigida | Por que este é o mais barato que a garante | Entrega |
|---|-------|--------|-------------------|---------------------------------------------|---------|
| 1 | ... | Haiku 4.5 | ... | ... | ... |
| 2 | ... | Opus 5.5 | ... | ... | ... |

**Ponto de decisão:** <quando houver planejamento, diga que a delegação da implementação será confirmada depois que o plano estiver pronto>
**Alertas:** <só se houver: Fable pode usar créditos extras; domínio de segurança/biologia pode acionar fallback>

Aprova? Você pode trocar o agente de qualquer etapa ou remover etapas.
```

Depois de mostrar o plano, **pare e espere a resposta**. Não comece nenhuma etapa antes. Se o usuário ajustar algo, atualize a tabela e siga com a versão ajustada.

### 4. Execução

**Forma preferida: os subagentes fixados.** Delegue a cada etapa pelo subagente correspondente (`deep-architect`, `planner`, `implementer`, `quick-worker`). Eles ficam em `~/.claude/agents/` e fixam o modelo pelo ID completo. Isso importa porque o parâmetro `model` da ferramenta de subagente só aceita aliases (`fable`, `opus`, `sonnet`, `haiku`), e em algumas versões do Claude Code um alias já resolveu para um modelo mais antigo do que o esperado. Com o ID fixado, você recebe exatamente o modelo que escolheu.

**Alternativa:** se os subagentes não estiverem instalados, use a ferramenta de subagente com o alias no parâmetro `model` e avise o usuário em uma linha que a instalação deles (ver `references/setup.md`) garante a versão exata.

Subagentes começam sem o contexto da conversa. Em cada delegação inclua:

- o objetivo da etapa e o pedido original do usuário
- os caminhos de arquivos relevantes
- as restrições e decisões já tomadas
- o formato exato da entrega esperada

Para o Fable, descreva o **resultado desejado** em vez de uma lista de passos: ele rende mais quando planeja o próprio caminho.

**Passagem de contexto entre etapas:** o agente de planejamento salva o plano em `PLAN.md` na raiz do projeto (ou em `docs/plans/<nome>.md` se essa pasta já existir). Os agentes de implementação leem esse arquivo antes de começar.

Etapas independentes podem rodar em paralelo; etapas que dependem de outra esperam.

### 5. Segundo ponto de aprovação (depois do planejamento)

Quando uma etapa de planejamento terminar:

1. Resuma o plano produzido em poucas linhas.
2. Mostre uma **nova tabela de delegação só para a implementação**, com as tarefas concretas do plano (ex.: "migrations do banco → Haiku 4.5", "lógica de permissões → Sonnet 5", "integração com pagamento → Opus 5.5").
3. Espere aprovação de novo.

### 6. Verificação e escalonamento

Toda entrega é verificada antes de seguir: testes passam, o resultado segue o plano, nada ficou pela metade. É isso que garante que escolher um modelo mais barato não custou qualidade.

Se a entrega não atingir a qualidade exigida, **não aceite e não remende**. Refaça a etapa um nível acima (Haiku 4.5 → Sonnet 5 → Opus 5.5 → Fable 5.1), avise o usuário em uma linha e continue. Uma falha basta para escalar. Escalar não exige nova aprovação, exceto quando o próximo nível é o Fable e ele pode usar créditos extras — aí pergunte antes.

O escalonamento é uma rede de segurança, não uma estratégia. Não escolha um modelo mais barato "para ver se dá" contando com escalar depois — se a escolha inicial já era duvidosa, ela estava errada.

### 7. Fechamento

Mostre um resumo curto: o que cada agente entregou, arquivos alterados e pendências. Se alguma etapa foi escalada, mencione.

## Exemplos

**Exemplo 1 — tarefa trivial**
Pedido: "O que faz a função `parseDate` em utils.ts?"
Ação: rodar a verificação de modelos, ler e responder direto. Sem plano.

**Exemplo 2 — uma etapa**
Pedido: "Renomeie `userId` para `accountId` em todo o projeto."
Plano: uma linha — Haiku 4.5, porque é substituição mecânica bem especificada e qualquer modelo daria o mesmo resultado. Pedir aprovação.

**Exemplo 3 — planejar e implementar uma feature**
Pedido: "Quero planejar um sistema de agendamento para uma clínica e depois implementar."

```
## Plano de delegação

**Tarefa:** Planejar e implementar sistema de agendamento para clínica

| # | Etapa | Agente | Qualidade exigida | Por que este é o mais barato que a garante | Entrega |
|---|-------|--------|-------------------|---------------------------------------------|---------|
| 1 | Mapear o código e a stack atuais | Haiku 4.5 | Resumo fiel da estrutura | Leitura sem decisões; modelos maiores dariam o mesmo resultado | Resumo da estrutura |
| 2 | Arquitetura, modelo de dados e fases | Opus 5.5 | Decisões corretas sobre conflitos de horário, fusos e permissões | Escopo de uma aplicação, bem delimitado: o Opus garante essa qualidade e o Fable não acrescentaria | PLAN.md |
| 3 | Implementação | a definir | — | Depende do que o plano revelar | — |
| 4 | Revisão final contra o PLAN.md | Opus 5.5 | Encontrar falhas de lógica e segurança | Mudança grande; revisão mais fraca deixaria passar erros | Relatório de revisão |

**Ponto de decisão:** depois da etapa 2, trago a divisão da implementação por agente para você aprovar.

Aprova? Você pode trocar o agente de qualquer etapa ou remover etapas.
```

**Exemplo 4 — quando o Fable se justifica**
Pedido: "Nosso monólito de 400 mil linhas precisa virar serviços. Planeja a migração inteira."
Etapa de planejamento → Fable 5.1: o problema exige investigar o sistema todo antes de decidir e não cabe em uma sessão; o Opus não garante essa qualidade nessa escala. Incluir o alerta de créditos extras.

## Configuração

Para tornar a skill realmente global e instalar os subagentes fixados, veja `references/setup.md`.
