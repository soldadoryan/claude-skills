# Como adicionar um modelo novo (só com aprovação do usuário)

Siga estes passos quando `scripts/check_models.py` encontrar um modelo novo **e o usuário aceitar** adicioná-lo.

## 1. Levante os fatos antes de mexer em qualquer arquivo

Consulte as páginas oficiais (use a ferramenta de busca na web ou de leitura de páginas):

- https://platform.claude.com/docs/en/about-claude/models/overview
- https://code.claude.com/docs/en/model-config

Confirme:

- o ID completo e o alias no Claude Code (se houver)
- a versão mínima do Claude Code que suporta o modelo
- onde ele fica na escala de custo e capacidade em relação aos modelos do registro
- se usa créditos extras ou tem fallback automático de segurança
- quais níveis de esforço (effort) aceita

Se não encontrar alguma dessas informações em fonte oficial, diga ao usuário o que ficou em aberto em vez de supor.

## 2. Decida o papel do modelo e confirme com o usuário

Há dois casos:

- **Versão nova de uma família existente** (ex.: Sonnet 5.5 no lugar de Sonnet 5): normalmente substitui a versão anterior no mesmo papel. Mostre ao usuário: "Sonnet 5.5 substitui o Sonnet 5 no papel de implementação."
- **Família ou nível novo** (ex.: um modelo acima do Fable, ou entre Sonnet e Opus): proponha em qual papel ele entra e o que ele faz melhor do que os vizinhos. Se não houver evidência de que ele muda alguma escolha, diga isso.

Aplique as mudanças só depois dessa confirmação.

## 3. Atualize os arquivos

Na pasta da skill (em geral `~/.claude/skills/agent-orchestrator/`):

1. **`models.json`**: adicione ou substitua a entrada (`id`, `alias`, `family`, `name`, `tier`, `subagent`, `min_claude_code`) e atualize `last_updated`. Mantenha os `tier` em ordem de custo, do mais barato (1) ao mais caro.
2. **`SKILL.md`**: atualize a tabela "Os agentes disponíveis", a cadeia de escalonamento da seção 6 e os exemplos que citam o modelo antigo.
3. **`references/model-guide.md`**: ajuste os critérios se o papel do modelo mudou.
4. **`assets/agents/`** e **`~/.claude/agents/`**: atualize o campo `model:` do subagente correspondente para o novo ID (ou crie um subagente novo para um nível novo, seguindo o formato dos existentes).

## 4. Confirme

Mostre ao usuário a lista de arquivos alterados e, se o modelo exigir uma versão mais nova do Claude Code, lembre de rodar `claude update`.
