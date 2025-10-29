NUIEvents = {}

NUIEvents.UpdateHUD = function()
    -- Envoie les valeurs brutes (0..1000) au HUD unifié
    local thirst = PlayerStatus["Thirst"]
    local hunger = PlayerStatus["Hunger"]
    TriggerEvent('vorp_hud:metabolism:update', thirst, hunger)
end

NUIEvents.ShowHUD = function(show)
    -- Redirigé vers le HUD unifié
    TriggerEvent('vorp_hud:metabolism:show', show)
end