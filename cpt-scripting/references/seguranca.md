# Segurança em scripts FiveM (Capital City)

Princípio: **o client é território do jogador**. Com um executor, ele dispara qualquer `TriggerServerEvent`, chama qualquer função Tunnel do server, repete qualquer fetch da NUI pelo devtools e lê qualquer arquivo shared/client. O server é a única fonte de verdade.

## Sumário
1. Modelo de ameaça
2. Esqueleto de evento seguro
3. Validação de parâmetros
4. Sessões (NUI e interações)
5. Cooldown, lock e race condition
6. Dinheiro e itens
7. Entidades e net IDs
8. Statebags
9. Banco de dados
10. Configurações sensíveis e logs
11. Limpeza
12. Proibido

## 1. Modelo de ameaça

Para cada evento client→server, pergunte:
- E se for chamado **sem** o jogador estar no local? → checar distância no server.
- E se for chamado **100 vezes por segundo**? → cooldown.
- E se dois disparos chegarem **ao mesmo tempo**? → lock por jogador.
- E se os argumentos forem **negativos, gigantes, NaN, string no lugar de número, tabela aninhada**? → validação de tipo e faixa.
- E se o **preço/quantidade/recompensa** vier do client? → nunca aceite; leia do `.sconfig.lua`.
- E se o **alvo** for outro jogador longe ou inexistente? → validar alvo e proximidade.
- E se o jogador **não tiver permissão**? → checar grupo/permissão a cada chamada, não só na abertura.

## 2. Esqueleto de evento seguro

Os nomes de funções do vRP abaixo são ilustrativos; use os do Mapa vRP.

```lua
RegisterNetEvent("capital_shop:buy", function(itemName, amount)
    local source = source
    local userId = vRP.getUserId(source)
    if not userId then return end

    local session = getSession(source, "shop")
    if not session then return end

    if not isString(itemName, 64) or not isInteger(amount, 1, SConfig.MaxAmount) then
        suspicious(source, userId, "capital_shop:buy parâmetros inválidos")
        return
    end

    local product = SConfig.Shops[session.id] and SConfig.Shops[session.id][itemName]
    if not product then return end

    if not isNear(source, Config.Shops[session.id].coords, Config.InteractDistance + 2.0) then return end
    if onCooldown(source, "buy", 750) then return end

    withLock(userId, function()
        local total = product.price * amount
        if not vRP.checkWeight(userId, itemName, amount) then
            return notify(source, "Inventário cheio.")
        end
        if vRP.tryPayment(userId, total) then
            vRP.giveInventoryItem(userId, itemName, amount)
            log("compras", ("[%d] comprou %dx %s por %d"):format(userId, amount, itemName, total))
        else
            notify(source, "Dinheiro insuficiente.")
        end
    end)
end)
```

Sempre `local source = source` na primeira linha: `source` é global e muda após qualquer `Wait`/chamada assíncrona.

## 3. Validação de parâmetros

```lua
local function isInteger(value, min, max)
    return type(value) == "number" and value == value and value % 1 == 0 and value >= min and value <= max
end

local function isNumber(value, min, max)
    return type(value) == "number" and value == value and value >= min and value <= max
end

local function isString(value, maxLength, pattern)
    if type(value) ~= "string" or #value == 0 or #value > maxLength then return false end
    return pattern == nil or value:match(pattern) ~= nil
end

local function isVector3(value)
    return type(value) == "vector3" or (type(value) == "table" and isNumber(value.x, -1e5, 1e5) and isNumber(value.y, -1e5, 1e5) and isNumber(value.z, -1e5, 1e5))
end
```

- `value == value` barra NaN; `value % 1 == 0` barra infinito e decimais.
- Nunca use um valor vindo do client como **chave de tabela** sem checar que a chave existe na config.
- Strings livres (nome, descrição, placa) sempre com limite de tamanho e, quando possível, padrão (`"^[%w ]+$"`).
- Tabelas vindas do client: valide cada campo usado e ignore o resto; nunca repasse a tabela inteira para banco ou para outros clients.

## 4. Sessões (NUI e interações)

O botão da NUI não prova nada: o fetch pode ser repetido pelo devtools a qualquer momento. Por isso, abertura de interface com ação sensível passa pelo server, que cria uma sessão:

```lua
local sessions = {}

local function openSession(source, kind, id, ttl)
    sessions[source] = { kind = kind, id = id, expires = GetGameTimer() + (ttl or 300000) }
end

local function getSession(source, kind)
    local session = sessions[source]
    if not session or session.kind ~= kind or GetGameTimer() > session.expires then return nil end
    return session
end

local function closeSession(source)
    sessions[source] = nil
end
```

- A abertura valida distância e permissão, cria a sessão e só então manda os dados ao client.
- Cada ação revalida sessão + distância (o jogador pode abrir e sair andando).
- O evento `close` da NUI encerra a sessão; `playerDropped` também.

## 5. Cooldown, lock e race condition

```lua
local cooldowns = {}
local locks = {}

local function onCooldown(source, key, ms)
    local now = GetGameTimer()
    local list = cooldowns[source]
    if not list then
        list = {}
        cooldowns[source] = list
    end
    if list[key] and now < list[key] then return true end
    list[key] = now + ms
    return false
end

local function withLock(userId, fn)
    if locks[userId] then return false end
    locks[userId] = true
    local ok, err = pcall(fn)
    locks[userId] = nil
    if not ok then print(("^1[%s] %s^0"):format(GetCurrentResourceName(), err)) end
    return ok
end
```

- **Lock** é o que impede duplicação quando há query assíncrona entre "checar" e "entregar". Sem ele, dois eventos simultâneos passam na mesma checagem.
- O `pcall` garante que o lock é liberado mesmo com erro.
- Use lock por `userId` (não por `source`) quando a ação mexe em dados persistentes do personagem.
- Recursos globais (baú compartilhado, estoque de loja) precisam de lock pela chave do recurso, não do jogador.

## 6. Dinheiro e itens

- Preço, quantidade máxima, recompensa, chance de drop: sempre no `.sconfig.lua`.
- Ordem obrigatória: **validar espaço/peso → cobrar (função que retorna bool) → entregar → logar**. Nunca entregar antes de confirmar a cobrança.
- Recompensas de "jobs" (entregas, farm): o server controla o estado da rota (etapa atual, ponto de entrega, hora de início) e só paga se o jogador está no ponto certo da etapa certa e se passou um tempo mínimo plausível.
- Multiplicações: confira overflow lógico (`price * amount` com `amount` limitado pelo `isInteger`).
- Transferências entre jogadores: validar os dois lados (existência, proximidade, saldo) dentro do mesmo lock.

## 7. Entidades e net IDs

```lua
local function getNearbyVehicle(source, netId, maxDistance)
    if not isInteger(netId, 1, 65535) then return nil end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return nil end
    local ped = GetPlayerPed(source)
    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > maxDistance then return nil end
    return entity
end
```

- Spawn de veículo pelo server: `CreateVehicleServerSetter` (OneSync), não `CreateVehicle` no server.
- Marque dono no server: `Entity(vehicle).state:set("owner", userId, true)` e confira no server antes de ações de dono.
- Alvo jogador (algemar, revistar, curar): valide `GetPlayerPed(target) ~= 0`, distância entre os dois e permissão de quem executa.
- Recomende no server.cfg `sv_entityLockdown "strict"` ou `"relaxed"` quando o script depender de spawn só pelo server (mencionar nos Avisos, pois é configuração do servidor).

## 8. Statebags

- O client pode escrever em statebags das entidades que controla e do próprio player. Portanto, **o server nunca confia em statebag que o client consegue escrever** para decidir dinheiro, item ou permissão.
- Estados de confiança são escritos só pelo server; se precisar detectar adulteração, use `AddStateBagChangeHandler` no server e reverta/logue.
- `GlobalState` é público: nunca coloque dados sensíveis nele.

## 9. Banco de dados

- Sempre parâmetros, nunca concatenação:

```lua
MySQL.single.await("SELECT id, amount FROM capital_storage WHERE user_id = ? AND slot = ?", { userId, slot })
```

- Com `vRP.prepare`, use os placeholders nomeados (`@user_id`) da própria base.
- Nomes de colunas/tabelas nunca vêm do client. Se precisar de ordenação dinâmica, use uma whitelist em tabela Lua.
- Operações que alteram saldo/estoque em concorrência: prefira update atômico (`UPDATE ... SET amount = amount - ? WHERE id = ? AND amount >= ?` e cheque `affectedRows`).

## 10. Configurações sensíveis e logs

- `.sconfig.lua`: preços, recompensas, webhooks, API keys, permissões, cooldowns, limites, chances.
- `.config.lua`: coordenadas, labels, textos, ícones, blips, distâncias de interação.
- Logs via `PerformHttpRequest` só no server, com URL do `.sconfig.lua`:

```lua
local function log(channel, message)
    local url = SConfig.Webhooks[channel]
    if not url then return end
    PerformHttpRequest(url, function() end, "POST", json.encode({ content = message }), { ["Content-Type"] = "application/json" })
end
```

- Logue toda ação econômica (quem, o quê, quanto, onde) e toda validação que falha de um jeito impossível para um client legítimo (tipo errado, item inexistente) via `suspicious()`. Falhas de distância podem ser lag: logue, não bana automaticamente.

## 11. Limpeza

```lua
AddEventHandler("playerDropped", function()
    local source = source
    sessions[source] = nil
    cooldowns[source] = nil
end)
```

Locks por `userId` também devem ser limpos no evento de logout do vRP (ver Mapa vRP).

## 12. Proibido

- `load`, `loadstring`, `ExecuteCommand` ou `os.execute` com dados vindos do client.
- Eventos server genéricos do tipo `giveItem(item, amount)` ou `addMoney(value)` acionáveis pelo client.
- Receber `source`/`userId` como argumento do client (`TriggerServerEvent("x", GetPlayerServerId(PlayerId()))`) e confiar nele.
- Verificações de permissão só no client (esconder botão não é segurança).
- Webhooks, tokens ou preços em `.config.lua`, `.client.lua` ou na NUI.
