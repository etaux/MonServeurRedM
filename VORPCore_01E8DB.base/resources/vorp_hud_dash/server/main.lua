local Core <const> = exports.vorp_core:GetCore()

RegisterNetEvent("vorp_hud:server:getData", function()
    local _source = source
    local User = Core.getUser(_source)
    if not User then return end

    local Character = User.getUsedCharacter
    if not Character then return end

    local charInfo = {
        firstname = Character.firstname or "Inconnu",
        lastname = Character.lastname or "",
        job = Character.job or "Sans-emploi",
        money = Character.money or 0,
        bank = Character.gold or 0,
        health = Character.healthOuter or Character.health or 100,
        hunger = 100,
        thirst = 100
    }

    TriggerClientEvent("vorp_hud:client:receiveData", _source, charInfo)
end)