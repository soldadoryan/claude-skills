local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPC = Tunnel.getInterface("vRP")

local resourceName = GetCurrentResourceName()
local sessions = {}
local cooldowns = {}
local locks = {}

local function isInteger(value, min, max)
    return type(value) == "number" and value == value and value % 1 == 0 and value >= min and value <= max
end

local function isString(value, maxLength, pattern)
    if type(value) ~= "string" or #value == 0 or #value > maxLength then return false end
    return pattern == nil or value:match(pattern) ~= nil
end

local function isNear(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= maxDistance
end

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

local function withLock(key, fn)
    if locks[key] then return false end
    locks[key] = true
    local ok, err = pcall(fn)
    locks[key] = nil
    if not ok then print(("^1[%s] %s^0"):format(resourceName, err)) end
    return ok
end

local function log(channel, message)
    local url = SConfig.Webhooks[channel]
    if not url or url == "" then return end
    PerformHttpRequest(url, function() end, "POST", json.encode({ content = message }), { ["Content-Type"] = "application/json" })
end

local function suspicious(source, userId, reason)
    log("suspeitos", ("[%s] user_id %s (source %d): %s"):format(resourceName, tostring(userId), source, reason))
end

local function openSession(source, kind, id, ttl)
    sessions[source] = { kind = kind, id = id, expires = GetGameTimer() + (ttl or 300000) }
end

local function getSession(source, kind)
    local session = sessions[source]
    if not session or session.kind ~= kind or GetGameTimer() > session.expires then return nil end
    return session
end

local function findPoint(id)
    for index = 1, #Config.Points do
        if Config.Points[index].id == id then return Config.Points[index] end
    end
end

RegisterNetEvent(resourceName .. ":open", function(pointId)
    local source = source
    local userId = vRP.getUserId(source)
    if not userId or not isString(pointId, 32) then return end
    if onCooldown(source, "open", 1000) then return end
    local point = findPoint(pointId)
    if not point or not isNear(source, point.coords, Config.InteractDistance + 2.0) then return end
    openSession(source, "shop", pointId)
    TriggerClientEvent(resourceName .. ":open", source, { products = SConfig.Shops[pointId] })
end)

RegisterNetEvent(resourceName .. ":close", function()
    sessions[source] = nil
end)

AddEventHandler("playerDropped", function()
    local source = source
    sessions[source] = nil
    cooldowns[source] = nil
end)
