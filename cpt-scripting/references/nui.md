# NUI (React + Vite) — padrão Capital

## Sumário
1. Estrutura e boilerplate
2. Vite
3. Tema e variáveis CSS
4. Comunicação NUI ↔ client
5. Abrir, fechar e foco
6. Desenvolvimento no navegador
7. Desempenho no front
8. Segurança no front
9. Build e entrega

## 1. Estrutura e boilerplate

Copie de `assets/nui/`:

```text
nui/
├── index.html
├── package.json
├── vite.config.js
└── src/
    ├── main.jsx
    ├── App.jsx
    ├── contexts/NuiContext.jsx
    ├── hooks/useRequest.js
    ├── hooks/useNuiEvent.js
    ├── utils/misc.js
    └── styles/
        ├── variables.css
        ├── global.css
        └── theme.js
```

Tecnologias: React, Vite, css-modules (padrão; styled-components só se pedido), react-icons, Context API.

Componentes em `src/components/NomeDoComponente/index.jsx` + `styles.module.css`. Telas em `src/pages/`.

## 2. Vite

```js
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  base: "./",
  build: { outDir: "dist", emptyOutDir: true, assetsInlineLimit: 4096, sourcemap: false },
});
```

`base: "./"` é obrigatório: o FiveM serve a NUI em `https://cfx-nui-<resource>/`, e caminhos absolutos (`/assets/...`) quebram a interface.

## 3. Tema e variáveis CSS

Com css-modules, as cores ficam em `src/styles/variables.css` (fácil de trocar). O `theme.js` continua existindo para uso em JS (ex.: cores dinâmicas em gráficos).

```css
:root {
  --dark: 0, 0, 0;
  --shape: 255, 255, 255;
  --primary: 3, 187, 232;
  --error: 255, 51, 0;
  --font-primary: "Montserrat", sans-serif;
}
```

Uso com opacidade: `background: rgba(var(--primary), 0.2);`, equivalente a `theme.colors.primary(0.2)`.

Fonte: empacote a Montserrat localmente (`@fontsource/montserrat`) em vez de depender do Google Fonts, para funcionar sem internet e sem atraso no primeiro carregamento.

`body` com `background: transparent`, `user-select: none` e `overflow: hidden`; a NUI cobre a tela inteira e qualquer fundo sólido tampa o jogo.

## 4. Comunicação NUI ↔ client

**Client → NUI**: envie tabelas direto, sem `json.encode` (o FiveM já serializa):

```lua
SendNUIMessage({ action = "open", vehicles = vehicles, coins = coins })
```

Se o script existente já envia strings JSON (como o Carshop faz com `JSON.parse(vehicles)`), mantenha a compatibilidade ao editar, mas em scripts novos envie tabelas.

**NUI escuta** com `useNuiEvent` (um listener só, despachando por `action`):

```jsx
useNuiEvent("open", (data) => {
  setShop({ action: "open", vehicles: data.vehicles, coins: data.coins });
});
useNuiEvent("close", () => setShop({}));
```

**NUI → client** com `useRequest`:

```js
const { request } = useRequest();
const response = await request("buy", { item: "water", amount: 2 });
```

**Client recebe o callback** e sempre chama `cb`, em qualquer caminho, senão o `fetch` fica pendente:

```lua
RegisterNUICallback("buy", function(data, cb)
    if type(data) ~= "table" then return cb({ ok = false }) end
    TriggerServerEvent("capital_shop:buy", data.item, data.amount)
    cb({ ok = true })
end)
```

Resultados que dependem do server (compra aprovada, saldo novo) voltam por evento server→client e então `SendNUIMessage({ action = "update", ... })`. A UI nunca assume sucesso antes disso.

## 5. Abrir, fechar e foco

```lua
local isOpen = false

local function openNui(payload)
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open", data = payload })
end

local function closeNui()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    TriggerServerEvent("capital_shop:close")
end

RegisterNUICallback("close", function(_, cb)
    closeNui()
    cb("ok")
end)
```

- ESC fecha pela NUI (`keydown` com `event.key === "Escape"`) chamando `request("close")`.
- Sempre libere o foco em `onResourceStop` e ao morrer/ser algemado, se fizer sentido no script.
- Use `SetNuiFocusKeepInput` só quando o jogador precisar andar com a UI aberta, e desabilite controles de ataque nesse caso.

## 6. Desenvolvimento no navegador

`isEnvBrowser()` detecta que está fora do FiveM; use-o para injetar dados de teste (`debugData`) e para `useRequest` retornar mocks. Assim a interface é desenvolvida com `npm run dev` sem abrir o jogo.

## 7. Desempenho no front

- Estado global mínimo no Context; estado de formulário/aba fica local no componente.
- `useMemo` para listas filtradas/ordenadas; `React.memo` em itens de listas grandes; `useCallback` em handlers passados para filhos.
- Listas com centenas de itens: paginação ou virtualização.
- Imagens em `.webp`, com `loading="lazy"`; nada de imagens remotas pesadas em cada abertura.
- Animações com `transform`/`opacity` (GPU), não com `top/left/width`.
- Não mantenha componentes pesados montados com a UI fechada: renderize `null` quando `action` estiver vazio.
- Remova `console.log` e listeners no cleanup dos `useEffect`.

## 8. Segurança no front

- Nenhum preço, cálculo final ou permissão decidido na NUI: ela só exibe o que o server mandou.
- Nunca renderize texto de outro jogador com `dangerouslySetInnerHTML` (XSS na NUI de todo mundo).
- Nada de keys, webhooks ou URLs de API no código da NUI; tudo que está em `dist/` é público.
- Debounce/desabilitar botão durante a requisição evita cliques duplos (conforto), mas **não substitui** cooldown e lock no server.

## 9. Build e entrega

- `npm install` e `npm run build` geram `nui/dist/`, que é o que o fxmanifest carrega.
- No server de produção, só `dist/` é necessária; `node_modules` e `src` podem ficar fora do deploy.
- Lembre o usuário desses passos nos Avisos da resposta quando entregar NUI nova.
