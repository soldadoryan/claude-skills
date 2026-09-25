local resourceName = GetCurrentResourceName()
local isOpen = false

local function closeNui()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
    TriggerServerEvent(resourceName .. ":close")
end

RegisterNetEvent(resourceName .. ":open", function(payload)
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open", data = payload })
end)

RegisterNUICallback("close", function(_, cb)
    closeNui()
    cb("ok")
end)

CreateThread(function()
    while true do
        local sleep = 1000
        if not isOpen then
            local coords = GetEntityCoords(PlayerPedId())
            for index = 1, #Config.Points do
                local point = Config.Points[index]
                local distance = #(coords - point.coords)
                if distance <= Config.DrawDistance then
                    sleep = 0
                    DrawMarker(27, point.coords.x, point.coords.y, point.coords.z - 0.97, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 3, 187, 232, 150, false, false, 2, false, nil, nil, false)
                    if distance <= Config.InteractDistance and IsControlJustPressed(0, 38) then
                        TriggerServerEvent(resourceName .. ":open", point.id)
                    end
                elseif distance <= Config.DrawDistance * 3 and sleep > 250 then
                    sleep = 250
                end
            end
        end
        Wait(sleep)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= resourceName then return end
    if isOpen then SetNuiFocus(false, false) end
end)
