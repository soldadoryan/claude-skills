# Como tornar a skill realmente global no Claude Code

A skill é acionada pela descrição, então o Claude pode pular ela em alguns prompts. Use uma das opções abaixo (ou as duas) para garantir.

## Opção 1 — CLAUDE.md (simples)

Adicione ao `~/.claude/CLAUDE.md` (vale para todos os projetos) ou ao `CLAUDE.md` do projeto:

```markdown
## Orquestração de agentes
Antes de iniciar qualquer tarefa que não seja trivial, siga a skill `agent-orchestrator`:
monte o plano de delegação (qual modelo faz cada etapa) e peça minha aprovação antes de executar.
```

## Opção 2 — Hook UserPromptSubmit (mais forte)

O texto que o hook imprime é injetado como contexto em todo prompt. Adicione ao `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Lembrete: use a skill agent-orchestrator. Se a tarefa não for trivial, mostre o plano de delegação e aguarde aprovação.'"
          }
        ]
      }
    ]
  }
}
```

Se já existir uma seção `hooks`, mescle em vez de substituir.

## Versão do Claude Code

O Opus 5.5 exige Claude Code v2.1.280 ou superior, e o Fable 5.1 exige v2.1.257 ou superior. Atualize com:

```bash
claude update
```

## Subagentes com modelo fixo (recomendado)

Os subagentes fixam cada modelo pelo ID completo, então você recebe exatamente a versão escolhida pelo orquestrador. Copie os arquivos de `assets/agents/` para `~/.claude/agents/` (global) ou `.claude/agents/` (projeto):

```bash
mkdir -p ~/.claude/agents
cp ~/.claude/skills/agent-orchestrator/assets/agents/*.md ~/.claude/agents/
```

São quatro: `deep-architect` (Fable 5.1), `planner` (Opus 5.5), `implementer` (Sonnet 5) e `quick-worker` (Haiku 4.5). Quando um modelo novo for adicionado com sua aprovação, o orquestrador atualiza esses arquivos também.

## Verificação de modelos novos

A skill roda `scripts/check_models.py` toda vez que é usada. O script consulta as páginas oficiais da Anthropic (e a API de modelos, se `ANTHROPIC_API_KEY` estiver definida) e compara com `models.json`. Ele precisa de Python 3 e acesso à internet; sem rede, a skill segue normalmente sem a verificação.

Se o Claude Code pedir permissão para rodar o script a cada vez, você pode liberar de forma permanente adicionando ao `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Bash(python3 ~/.claude/skills/agent-orchestrator/scripts/check_models.py)"]
  }
}
```

## Comando `/full-strong`

No Claude Code, um prompt que **começa** com `/` é tratado como comando. Sem instalar o comando abaixo, digitar `/full-strong planeja o sistema...` pode dar erro de comando desconhecido. Instale uma vez:

```bash
mkdir -p ~/.claude/commands
cp ~/.claude/skills/agent-orchestrator/assets/commands/full-strong.md ~/.claude/commands/
```

Depois disso, `/full-strong <tarefa>` funciona no início do prompt. No meio do texto (ex.: `planeja a migração /full-strong`), a string funciona mesmo sem o comando.
