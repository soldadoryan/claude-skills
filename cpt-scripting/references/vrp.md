# Análise do vRP da Capital City

Existem muitas variações de vRP (vRPex, Creative v1–v7, Network, bases próprias) e os nomes de funções mudam entre elas (`getUserId` vs `Passport`, `getInventoryItemAmount` vs `ItemAmount`, `hasPermission` vs `HasGroup`). Por isso, antes da primeira implementação, analise o vRP real da base em vez de supor.

## Quando fazer

- Na primeira implementação da conversa: obrigatório.
- Nas seguintes: reutilize o Mapa vRP já gerado. Só reanalise se o usuário disser que o vRP mudou ou se uma função necessária não estiver no mapa.
- Se o usuário colar um Mapa vRP salvo de conversas anteriores, use-o direto.

## O que ler

Se tiver acesso aos arquivos (upload, repositório, Claude Code), leia nesta ordem:

1. `vrp/fxmanifest.lua` — ordem de carregamento e dependências (driver de banco).
2. `vrp/lib/utils.lua`, `vrp/lib/Tunnel.lua`, `vrp/lib/Proxy.lua` — como interfaces são expostas.
3. `vrp/modules/*.lua` (ou `vrp/server/*.lua`) — funções de usuário, dinheiro, inventário, grupos, identidade.
4. `vrp/base.lua` / `vrp/server/base.lua` — `prepare`, `query`, `execute`, ciclo de login/logout.
5. `vrp/client/*.lua` — funções client expostas via Tunnel (`vRPC`).

Se não tiver acesso, peça esses arquivos ao usuário antes de usar qualquer função do vRP. Enquanto isso, é aceitável escrever o esqueleto com nomes genéricos, desde que isso apareça nos Avisos como "a confirmar".

## O que extrair (Mapa vRP)

Gere este mapa na resposta da primeira análise, preenchido com os nomes reais e a assinatura de cada função:

```markdown
## Mapa vRP — Capital City

Interface
- Obter interface server: `vRP = Proxy.getInterface("vRP")`
- Obter interface client: `vRPC = Tunnel.getInterface("vRP")`
- Expor interface do resource: ...

Identidade
- user_id a partir do source: ...
- source a partir do user_id: ...
- nome/identidade do personagem: ...

Permissões / grupos
- verificar permissão: ...
- verificar grupo: ...

Dinheiro
- saldo carteira / banco: ...
- pagamento com verificação (retorna bool): ...
- dar dinheiro: ...

Inventário
- quantidade de item: ...
- remover item com verificação (retorna bool): ...
- dar item: ...
- checar peso/espaço antes de dar: ...
- nome/índice de item: ...

Banco de dados
- driver: (oxmysql / ghmattimysql / mysql-async / próprio)
- preparar query: ...
- executar/consultar: ... (síncrono? retorna tabela?)

Dados do usuário
- ler/gravar dado persistente (getUData / setUData ou equivalente): ...

Ciclo de vida
- evento de login/spawn: ...
- evento de logout/drop: ...

Client (vRPC)
- notificação: ...
- animação / progress bar: ...
- outras úteis: ...
```

Ao final, sugira ao usuário salvar o mapa em `references/vrp-mapa.md` dentro da skill, para que as próximas conversas não precisem repetir a análise. Se esse arquivo existir, leia-o no lugar desta análise.

## Pontos a observar na análise

- **Funções que retornam bool** para pagamento e remoção de item: são as únicas que devem ser usadas antes de dar recompensa. Se só existir "remover" sem retorno, faça "checar quantidade" + "remover" no mesmo tick sem `Wait` entre eles e registre o risco nos Avisos.
- **Checagem de peso/espaço**: sem ela o item some quando o inventário está cheio. Sempre verifique antes de entregar.
- **Queries síncronas vs assíncronas**: chamadas assíncronas abrem janela para race condition (duplicação). Use lock por jogador (ver `seguranca.md`).
- **Funções Tunnel do server expostas ao client**: qualquer função do server registrada via `Tunnel.bindInterface` pode ser chamada por um cheater com qualquer argumento. Trate cada uma como um evento de rede e valide tudo.
- **Notificação padrão** da base: use a mesma para manter consistência visual.

## Padrão de uso no resource

```lua
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface("vRP")
```

Confirme com o Mapa vRP se é assim que a base expõe as interfaces antes de usar.
