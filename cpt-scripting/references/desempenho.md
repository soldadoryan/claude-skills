# Desempenho em scripts FiveM (Capital City)

Meta: **0.00–0.01 ms no resmon com o jogador longe** de qualquer ponto do script e no máximo ~0.10 ms perto de uma interação ativa. Server sem threads rodando à toa.

## Sumário
1. Threads no client
2. Distâncias e zonas
3. Teclas e input
4. Rede (eventos, Tunnel, broadcast)
5. Statebags
6. Cache em memória
7. Banco de dados
8. Entidades, modelos e blips
9. Server threads
10. NUI

## 1. Threads no client

Uma thread por responsabilidade, com `Wait` dinâmico:

```lua
CreateThread(function()
    while true do
        local sleep = 1000
        local coords = GetEntityCoords(PlayerPedId())
        for index = 1, #Config.Points do
            local point = Config.Points[index]
            local distance = #(coords - point.coords)
            if distance <= Config.DrawDistance then
                sleep = 0
                DrawMarker(27, point.coords.x, point.coords.y, point.coords.z - 0.97, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 3, 187, 232, 150, false, false, 2, false, nil, nil, false)
                if distance <= Config.InteractDistance and IsControlJustPressed(0, 38) then
                    TriggerServerEvent("capital_shop:open", point.id)
                end
            elseif distance <= Config.DrawDistance * 3 and sleep > 250 then
                sleep = 250
            end
        end
        Wait(sleep)
    end
end)
```

- Longe: `Wait(1000)` ou mais. Médio: `Wait(250–500)`. Perto e desenhando: `Wait(0)`.
- Chame `PlayerPedId()` e `GetEntityCoords` uma vez por iteração, não por ponto.
- Use `for i = 1, #t` em listas; `pairs` só em dicionários.
- Com muitos pontos (centenas), pré-filtre por grade/região ou use a lib de zonas da base em vez de iterar tudo.
- Nada de `Wait(0)` permanente para checar algo que muda raramente (ex.: "está em veículo?"); use eventos (`gameEventTriggered`, `baseevents`) ou checagem a cada 500 ms.
- Encerre threads que não são mais necessárias (flag de controle) em vez de deixá-las em `Wait` eterno.

## 2. Distâncias e zonas

- `#(vecA - vecB)` é muito mais barato que `GetDistanceBetweenCoords`.
- Guarde coordenadas da config como `vector3(...)` (não tabelas `{x=,y=,z=}`), para operar direto.
- Para comparar sem raiz, compare com o quadrado da distância quando fizer sentido em loops pesados.

## 3. Teclas e input

- Ações globais (abrir tablet, menu): `RegisterKeyMapping` + `RegisterCommand` (o jogador pode remapear e não há thread).
- `IsControlJustPressed` só dentro de threads que já estão em `Wait(0)` por proximidade.

```lua
RegisterCommand("+capital_tablet", function() openTablet() end, false)
RegisterCommand("-capital_tablet", function() end, false)
RegisterKeyMapping("+capital_tablet", "Abrir tablet", "keyboard", "F9")
```

## 4. Rede (eventos, Tunnel, broadcast)

- Nunca dispare eventos de rede dentro de thread `Wait(0)`. Rede só em resposta a ações (tecla, entrada em zona, clique).
- Agrupe dados: um evento com a lista toda em vez de um por item.
- Envie ao client só o necessário para a tela atual; nada de mandar a tabela inteira do banco.
- `TriggerClientEvent(..., -1, ...)`: só para algo realmente global, pequeno e raro. Para "jogadores próximos", itere os jogadores e filtre por distância no server; para estado de uma entidade, use statebag da entidade (só replica para quem tem a entidade em escopo).
- Callbacks Tunnel que retornam dados são assíncronos e têm ida e volta: não os chame em loop.
- `TriggerLatentClientEvent` para payloads grandes e não urgentes (ex.: catálogo inicial), evitando travar o canal de rede.

## 5. Statebags

- Bons usos: flags e valores pequenos ligados a entidade/jogador (`isCuffed`, `owner`, `fuel` arredondado).
- Evite: tabelas grandes, valores que mudam a cada frame, histórico, listas de itens.
- `replicated = false` quando só o server precisa do valor.
- Atualize só quando o valor mudar de fato (compare antes de `state:set`).

## 6. Cache em memória

- Cache é otimização, não requisito: use quando a mesma leitura do banco acontece muitas vezes.
- Regras: carregar no login/abertura, escrever no banco em toda alteração relevante (ou em lote periódico **e** no logout/`onResourceStop`), limpar no `playerDropped`.
- Se não houver garantia de persistência (crash do server perde dados), não use cache para dinheiro/itens; registre a escolha nos Avisos.
- Dados estáticos (catálogo, preços) podem ficar em cache pela vida do resource.

## 7. Banco de dados

- Nada de query dentro de loop/thread frequente.
- Índices nas colunas usadas em `WHERE`/`JOIN` (entregue no `CREATE TABLE`).
- `SELECT` só das colunas usadas; nada de `SELECT *`.
- Várias escritas relacionadas: uma transação ou um `INSERT ... VALUES (...), (...)` em lote.
- Prepare as queries na inicialização (`vRP.prepare`) se a base usa esse padrão.

## 8. Entidades, modelos e blips

```lua
local function loadModel(model)
    local hash = type(model) == "number" and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) do
        if GetGameTimer() > timeout then return nil end
        Wait(10)
    end
    return hash
end
```

- Após criar a entidade: `SetModelAsNoLongerNeeded(hash)`.
- NPCs/props de ponto fixo: crie ao se aproximar e delete ao se afastar (ou use a lib de zonas), não mantenha todos no mapa.
- Guarde handles criados (entidades, blips) em tabelas locais e limpe em `onResourceStop`:

```lua
AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for index = 1, #createdEntities do
        if DoesEntityExist(createdEntities[index]) then DeleteEntity(createdEntities[index]) end
    end
    for index = 1, #createdBlips do
        RemoveBlip(createdBlips[index])
    end
    SetNuiFocus(false, false)
end)
```

- Blips: crie uma vez na inicialização, não dentro de loop.
- Texto 3D/markers: desenhe só dentro do raio de visão.

## 9. Server threads

- Só quando inevitável (expiração de itens, respawn de estoque, pagamento de salário).
- Intervalos longos (minutos) e trabalho em lote: uma query para todos, não uma por jogador.
- Para "daqui a X segundos faça Y" use `SetTimeout`, não uma thread com `Wait`.

## 10. NUI

- `SendNUIMessage` só quando algo muda; nunca em loop com `Wait(0)`.
- Payloads grandes (catálogo): enviar uma vez na abertura; atualizações seguintes só com o diff.
- Detalhes do front-end (re-render, imagens, build) em `nui.md`.
