local playerData = nil
local hudState = {
    hunger = nil,
    thirst = nil,
}

-- Étape 1 : Recevoir les données du serveur et les stocker
RegisterNetEvent("vorp_hud:client:receiveData")
AddEventHandler("vorp_hud:client:receiveData", function(data)
    playerData = data
end)

-- Étape 2 : Masquer le HUD de base de RedM
Citizen.CreateThread(function()
    while true do
        DisplayHud(false)
        DisplayRadar(false)
        Citizen.Wait(1000)
    end
end)

-- Étape 3 : Boucle pour demander les données au serveur toutes les 10 secondes
Citizen.CreateThread(function()
    -- On attend que le joueur soit bien chargé dans la session
    while not NetworkIsSessionStarted() do Citizen.Wait(500) end
    Citizen.Wait(5000) -- Délai de sécurité supplémentaire

    while true do
        TriggerServerEvent("vorp_hud:server:getData")
        Citizen.Wait(5000) -- on allège (argent actualisé via event 'vorp:updateUi')
    end
end)

-- Étape 4 : Boucle pour envoyer les données au HUD (partie visuelle)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000) -- Rafraîchit les infos non-critiques toutes les 2 secondes

        if playerData then
            local ped = PlayerPedId()

            SendNUIMessage({
                action = "update",
                data = {
                    name = playerData.firstname .. " " .. playerData.lastname,
                    job = playerData.job,
                    money = playerData.money,
                    bank = playerData.bank,
                    hunger = hudState.hunger or playerData.hunger,
                    thirst = hudState.thirst or playerData.thirst,
                    time = string.format("%02d:%02d", GetClockHours(), GetClockMinutes())
                }
            })
        end
    end
end)

-- Écoute les updates monétaires du core
RegisterNetEvent('vorp:updateUi')
AddEventHandler('vorp:updateUi', function(payload)
    -- payload: json string { type="ui", action="update", moneyquanty, goldquanty, ... }
    local ok, data = pcall(json.decode, payload)
    if not ok or type(data) ~= 'table' then return end
    if data.action ~= 'update' then return end
    if not playerData then playerData = {} end
    playerData.money = tonumber(data.moneyquanty) or playerData.money
    playerData.bank = tonumber(data.goldquanty) or playerData.bank
end)

-- Boucle vitale rapide (santé/stamina) pour une sensation fluide
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200) -- 5x par seconde
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local stamina = Citizen.InvokeNative(0x36731AC041289BB1, ped, Citizen.ResultAsInteger())
        SendNUIMessage({ action = 'vitals', data = { health = health, stamina = stamina } })
    end
end)

-- Intégration: Metabolism (redirigé depuis vorp_metabolism)
RegisterNetEvent('vorp_hud:metabolism:update')
AddEventHandler('vorp_hud:metabolism:update', function(thirst, hunger)
    -- valeurs brutes vorp_metabolism: 0..1000 -> pourcentage 0..100
    hudState.thirst = math.floor((thirst or 0) / 10)
    hudState.hunger = math.floor((hunger or 0) / 10)

    SendNUIMessage({
        action = 'metabolismUpdate',
        data = { thirst = hudState.thirst, hunger = hudState.hunger }
    })
end)

RegisterNetEvent('vorp_hud:metabolism:show')
AddEventHandler('vorp_hud:metabolism:show', function(show)
    SendNUIMessage({ action = show and 'show' or 'hide' })
end)

-- Intégration: Progress Bar unifiée
local progressActive = false
RegisterNetEvent('vorp_hud:progress:start')
AddEventHandler('vorp_hud:progress:start', function(message, milliseconds, opts)
    if progressActive then return end
    progressActive = true
    SendNUIMessage({
        action = 'progressStart',
        data = { message = message, time = milliseconds, theme = opts and opts.theme, color = opts and opts.color, width = opts and opts.width }
    })
end)

RegisterNetEvent('vorp_hud:progress:cancel')
AddEventHandler('vorp_hud:progress:cancel', function()
    progressActive = false
    SendNUIMessage({ action = 'progressCancel' })
end)

RegisterNetEvent('vorp_hud:progress:finish')
AddEventHandler('vorp_hud:progress:finish', function()
    progressActive = false
    SendNUIMessage({ action = 'progressFinish' })
end)

-- NUI -> Client : fin de progression
RegisterNUICallback('progressFinished', function(_, cb)
    TriggerEvent('vorp_hud:progress:finished')
    if cb then cb('ok') end
end)