local isOpen = false

local function setUi(state)
    isOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'toggle',
        visible = state
    })
end

RegisterCommand('jobcreator', function()
    setUi(not isOpen)
end, false)

RegisterKeyMapping('jobcreator', 'Open Job Creator', 'keyboard', 'F7')

RegisterNUICallback('close', function(_, cb)
    setUi(false)
    cb({ ok = true })
end)

RegisterNUICallback('notify', function(data, cb)
    local message = data and data.message or 'Operazione completata.'
    TriggerEvent('chat:addMessage', {
        color = { 102, 194, 255 },
        multiline = false,
        args = { 'JobCreator', message }
    })
    cb({ ok = true })
end)

RegisterNUICallback('saveJob', function(data, cb)
    if not data or type(data) ~= 'table' then
        cb({ ok = false, error = 'Invalid payload' })
        return
    end

    TriggerServerEvent('lunar-jobcreator:server:saveJob', data)

    TriggerEvent('chat:addMessage', {
        color = { 122, 255, 146 },
        multiline = false,
        args = {
            'JobCreator',
            ('Job "%s" inviato al server.'):format(data.label or 'Sconosciuto')
        }
    })

    cb({ ok = true, saved = true })
end)

CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
        end
        Wait(0)
    end
end)
