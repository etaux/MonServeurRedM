-- Queue all progress tasks to prevent infinite loops and overlap
local queue = {}
local function _internalStart(message, miliseconds, cb, theme, color, width, focus)
    if theme == nil then
        theme = "linear"
    end

    if color == nil then
        color = 'rgb(124, 45, 45)'
    end
    
    if width == nil then
        width = '20vw'
    end

    table.insert(queue, {
        message = message,
        callback = cb,
        focus = focus
    })

    -- Redirige vers HUD unifié
    TriggerEvent('vorp_hud:progress:start', message, miliseconds, { theme = theme, color = color, width = width })
end


exports('initiate', function()
    local self = {}
    self.start = _internalStart
    return self
end)

-- Support `progressBar` resources `startUI` Export.
AddEventHandler('__cfx_export_progressBars_startUI', function(callback)
    callback(function (time, text)
        _internalStart(text, time, nil, nil, nil, nil, false)
    end)
end)

function CancelNext()
    local cancelled = {}
    if queue[1] ~= nil then
        TriggerEvent('vorp_hud:progress:cancel')
        cancelled = queue[1];
        table.remove(queue, 1)
    end
    return cancelled;
end

exports('CancelNext', function(cb)
    local cancelled = CancelNext()
    if cb ~= nil then
        cb(cancelled)
    end
end)

exports('CancelAll', function(cb)
    local cancelled = {}
    while queue[1] ~= nil do
        table.insert(cancelled, CancelNext())
    end
    if cb ~= nil then
        cb(cancelled)
    end
end)

-- Écoute la fin depuis le HUD unifié
RegisterNetEvent('vorp_hud:progress:finished')
AddEventHandler('vorp_hud:progress:finished', function()
    if queue[1] and queue[1].callback then
        queue[1].callback()
    end
    if queue[1] then
        table.remove(queue, 1)
    end
end)