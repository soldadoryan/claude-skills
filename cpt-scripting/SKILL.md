---
name: cpt-scripting
description: Padrão oficial do Grupo Capital para criar, editar, revisar, otimizar ou corrigir scripts FiveM da base Capital City (vRP, Lua client/server, fxmanifest, NUI em React/Vite). Use SEMPRE que o pedido envolver FiveM, GTA RP, vRP, resource, fxmanifest, eventos client/server, Tunnel/Proxy, NUI, statebags, threads, exploits/anticheat de script, resmon ou "fazer um script", mesmo que o usuário não cite "Capital" nem o nome da skill.
---

# cpt-scripting — Scripts FiveM do Grupo Capital

Esta skill define como construir resources para a base **Capital City** (framework vRP). O objetivo de todo script é ser **seguro** (nada que o client mande é confiável) e **leve** (resmon próximo de 0.00ms em idle). Quando uma regra daqui conflitar com um pedido explícito do usuário, siga o usuário e registre o desvio na seção de avisos da resposta.

## Mapa da skill

Leia o arquivo de referência correspondente antes de escrever o código daquela parte:

| Arquivo | Quando ler |
|---|---|
| `references/vrp.md` | Antes da primeira implementação da conversa (análise obrigatória do vRP) |
| `references/seguranca.md` | Sempre que houver evento client→server, NUI callback, Tunnel, dinheiro, itens, entidades ou SQL |
| `references/desempenho.md` | Sempre que houver thread, loop, marker, blip, entidade, statebag, evento broadcast ou query frequente |
| `references/nui.md` | Sempre que o script tiver interface |
| `assets/lua/*` | Templates de `fxmanifest.lua` e esqueletos client/server/config |
| `assets/nui/*` | Boilerplate da NUI (vite config, hooks, tema, variáveis CSS) |

## Fluxo de trabalho

1. **Analisar o vRP** (só na primeira implementação da conversa): siga `references/vrp.md`, gere o "Mapa vRP" e reutilize-o nas implementações seguintes sem reanalisar. Se o código do vRP não estiver disponível na conversa, peça ao usuário os arquivos indicados em `references/vrp.md` antes de escrever chamadas a funções do vRP; nunca invente nomes de função.
2. **Planejar o fluxo de dados**: defina o que roda no client, o que roda no server e quais mensagens trafegam. Regra de ouro: o client pede, o server decide.
3. **Escrever o código** seguindo as regras abaixo e as referências.
4. **Revisar** com o checklist final antes de responder.
5. **Responder** no formato de entrega definido no fim deste arquivo.

## Regras gerais

1. Back-end em **Lua 5.4** (`lua54 'yes'`); interfaces em **React + Vite**.
2. **Nenhum comentário** no código gerado (Lua, JS, JSX, CSS). Explicações vão no texto da resposta, nunca dentro dos arquivos.
3. Todo desvio deste padrão (a pedido do usuário ou por necessidade técnica) é listado na seção **⚠️ Avisos** no fim da resposta, com o motivo.
4. Segurança e desempenho vêm antes de conveniência. Se uma feature pedida só funciona de forma insegura, implemente a versão segura e explique a diferença nos avisos.
5. Nomes de eventos, callbacks e statebags sempre prefixados com o nome do resource (`capital_garage:spawn`), para evitar colisão e facilitar auditoria.
6. Use `CreateThread`, `Wait`, `RegisterNetEvent(name, handler)` (formas modernas), nunca `Citizen.CreateThread`/`RegisterServerEvent` + `AddEventHandler` separados.
7. Variáveis e funções sempre `local` no escopo do arquivo; globais só quando o vRP exigir (ex.: `vRP`, `vRPC`, interfaces de Tunnel).
8. Ao editar um script existente, preserve a estrutura, os nomes de eventos já usados por outros resources e o estilo do arquivo; mude só o necessário e aponte o que foi alterado.

## Estrutura de pasta

```text
📁 nome_do_script/
├── 📁 nui/
│   ├── 📁 public/
│   ├── 📁 src/
│   ├── 📄 index.html
│   ├── 📄 package.json
│   └── 📄 vite.config.js
├── 📄 main.client.lua
├── 📄 main.server.lua
├── 📄 main.config.lua
├── 📄 main.sconfig.lua
└── 📄 fxmanifest.lua
```

Sufixos e o que vai em cada um:

| Sufixo | Lado | Conteúdo |
|---|---|---|
| `.client.lua` | client | Threads de proximidade, markers, NUI, natives de render/input |
| `.server.lua` | server | Toda regra de negócio, validação, dinheiro, itens, banco, logs |
| `.config.lua` | shared | Só o que o client **precisa** saber: coordenadas, labels, textos, blips |
| `.sconfig.lua` | server | Preços, recompensas, webhooks, keys, permissões, limites, cooldowns, chances |

Arquivos `.config.lua` são baixados pelo client e podem ser lidos por qualquer jogador. Na dúvida se um valor é sensível, coloque no `.sconfig.lua` e envie ao client só o necessário no momento da abertura.

Scripts maiores podem dividir em vários arquivos com o mesmo sufixo (`garage.server.lua`, `impound.server.lua`); o glob do fxmanifest já os carrega.

## fxmanifest padrão

Use `assets/lua/fxmanifest.lua`. Para scripts sem NUI, remova `ui_page` e `files`.

```lua
fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Grupo Capital"
description "Resource desenvolvido por Grupo Capital"
version "1.0.0"

shared_scripts { "@vrp/lib/utils.lua", "*.config.lua" }
client_scripts { "*.client.lua" }
server_scripts { "@oxmysql/lib/MySQL.lua", "*.server.lua", "*.sconfig.lua" }

ui_page "nui/dist/index.html"

files { "nui/dist/**/*" }
```

Ajuste a linha do banco (`@oxmysql/lib/MySQL.lua`) conforme o driver que o vRP da base usa (ver Mapa vRP); se o acesso ao banco for só via `vRP.prepare/query`, remova-a.

## Padrão de comunicação

O fluxo seguro para qualquer ação com efeito (comprar, vender, spawnar, dar item):

```text
Client (tecla/zona) ──► Server: pede abertura
Server: valida identidade, distância, permissão ──► cria sessão ──► Client: dados mínimos
Client ──► NUI: SendNUIMessage({ action = "open", ... })
NUI ──► Client: fetch(callback) ──► Server: TriggerServerEvent
Server: revalida sessão + distância + parâmetros + cooldown + lock ──► executa ──► log
Server ──► Client: resultado ──► NUI: atualiza
```

Nunca aplique no client o resultado de uma ação antes do server confirmar (ex.: descontar dinheiro na UI). Detalhes e código em `references/seguranca.md`.

## Interfaces (resumo)

- React + Vite, **css-modules** por padrão (styled-components só se pedido).
- Cores e fontes em variáveis CSS globais (`src/styles/variables.css`) derivadas do tema:

```js
export const theme = {
  colors: {
    dark: (opacity = 1) => `rgba(0, 0, 0, ${opacity})`,
    shape: (opacity = 1) => `rgba(255, 255, 255, ${opacity})`,
    primary: (opacity = 1) => `rgba(3, 187, 232, ${opacity})`,
    error: (opacity = 1) => `rgba(255, 51, 0, ${opacity})`,
  },
  fonts: { family: { primary: "'Montserrat', sans-serif" } },
};
```

- Comunicação via `useRequest()` e `useNuiEvent()`; estado global via Context API; ícones com `react-icons`.
- O tema pode ser trocado se o prompt pedir.
- `vite.config.js` precisa de `base: "./"` ou a NUI abre em branco no FiveM.

Tudo o mais (boilerplate, ESC, foco, modo browser, build) está em `references/nui.md`.

## Checklist antes de responder

Segurança:
- [ ] Todo `RegisterNetEvent` do server usa `local source = source` e valida `user_id`
- [ ] Todos os parâmetros vindos do client têm tipo, faixa e tamanho validados
- [ ] Preço, recompensa e quantidade máxima vêm do `.sconfig.lua`, nunca do client
- [ ] Distância/localização conferida no server para ações ligadas a um lugar
- [ ] Cooldown e lock por jogador em ações que mexem com dinheiro/itens
- [ ] Remoção de item/dinheiro é verificada (`if tryPayment then ... end`) antes de entregar a recompensa
- [ ] SQL só com parâmetros nomeados, nunca concatenação
- [ ] Nenhum webhook, key ou valor econômico em arquivo shared/client
- [ ] `playerDropped` limpa sessões, locks e caches do jogador

Desempenho:
- [ ] Threads do client com `Wait` dinâmico (longe = 1000ms+, perto = 0)
- [ ] Distâncias com `#(a - b)`, nunca `GetDistanceBetweenCoords`
- [ ] Teclas via `RegisterKeyMapping` quando não dependem de zona
- [ ] Nenhum `TriggerClientEvent(..., -1, ...)` com payload grande ou frequente
- [ ] `onResourceStop` remove entidades, blips, foco de NUI e props criados
- [ ] Modelos carregados com timeout e liberados com `SetModelAsNoLongerNeeded`

NUI:
- [ ] Todo `RegisterNUICallback` chama `cb` em qualquer caminho
- [ ] Foco liberado ao fechar (ESC, callback `close` e `onResourceStop`)
- [ ] `base: "./"` no Vite e cores em `variables.css`

## Formato de entrega

Responda sempre nesta ordem:

1. **Resumo** curto do que foi feito e do fluxo (client/server/NUI).
2. **Arquivos**, cada um completo e com o caminho no título (`📄 main.server.lua`). Em edições pequenas, mostre só as funções alteradas e diga onde entram.
3. **🔒 Medidas de segurança** implementadas ou ajustadas, em lista, cada item dizendo que ataque ele impede.
4. **⚡ Medidas de desempenho** implementadas ou ajustadas, em lista, cada item dizendo o ganho.
5. **⚠️ Avisos**: desvios do padrão, suposições sobre funções do vRP não confirmadas, dependências externas (oxmysql, pacotes npm) e passos manuais (ex.: `npm run build`, `ensure` no server.cfg, tabela SQL a criar). Se não houver nenhum, escreva "Nenhum desvio do padrão."

Se o script precisar de tabela no banco, entregue o `CREATE TABLE` com índices nas colunas usadas em `WHERE`.
