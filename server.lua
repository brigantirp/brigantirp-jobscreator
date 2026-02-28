local RESOURCE_NAME = GetCurrentResourceName()
local DATA_PATH = 'data/jobs.json'

local cache = {
    jobs = {}
}

local function loadJobs()
    local raw = LoadResourceFile(RESOURCE_NAME, DATA_PATH)
    if not raw or raw == '' then
        cache.jobs = {}
        return
    end

    local parsed = json.decode(raw)
    if type(parsed) ~= 'table' then
        print(('[%s] Invalid %s file, resetting cache.'):format(RESOURCE_NAME, DATA_PATH))
        cache.jobs = {}
        return
    end

    cache.jobs = parsed
end

local function persistJobs()
    local encoded = json.encode(cache.jobs)
    SaveResourceFile(RESOURCE_NAME, DATA_PATH, encoded, -1)
end

local function normalizeString(value, fallback)
    if type(value) ~= 'string' then
        return fallback
    end

    local trimmed = value:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then
        return fallback
    end

    return trimmed
end

local function normalizeJob(payload)
    local job = {
        name = normalizeString(payload.name, nil),
        label = normalizeString(payload.label, 'Unnamed Job'),
        description = normalizeString(payload.description, ''),
        icon = normalizeString(payload.icon, '💼'),
        type = normalizeString(payload.type, 'legal'),
        color = normalizeString(payload.color, '#2563eb'),
        webhook = normalizeString(payload.webhook, ''),
        grades = {},
        zones = {},
        options = {
            canHandcuff = payload.options and payload.options.canHandcuff == true,
            canImpound = payload.options and payload.options.canImpound == true,
            dutySystem = payload.options and payload.options.dutySystem ~= false,
            billingEnabled = payload.options and payload.options.billingEnabled ~= false,
            whitelistOnly = payload.options and payload.options.whitelistOnly == true
        },
        updatedAt = os.time()
    }

    if not job.name then
        return nil, 'Nome interno mancante.'
    end

    if type(payload.grades) == 'table' then
        for index, grade in ipairs(payload.grades) do
            local salary = tonumber(grade.salary) or 0
            job.grades[#job.grades + 1] = {
                name = normalizeString(grade.name, ('grade_%s'):format(index - 1)),
                label = normalizeString(grade.label, ('Grade %s'):format(index - 1)),
                salary = math.floor(salary),
                boss = grade.boss == true
            }
        end
    end

    if type(payload.zones) == 'table' then
        for _, zone in ipairs(payload.zones) do
            job.zones[#job.zones + 1] = {
                type = normalizeString(zone.type, 'generic'),
                coords = normalizeString(zone.coords, '0.0,0.0,0.0')
            }
        end
    end

    return job
end

local function upsertJob(job)
    for i = 1, #cache.jobs do
        if cache.jobs[i].name == job.name then
            cache.jobs[i] = job
            return 'updated'
        end
    end

    cache.jobs[#cache.jobs + 1] = job
    return 'created'
end

local function registerStashesForJob(job)
    if GetResourceState('ox_inventory') ~= 'started' then
        return
    end

    for _, zone in ipairs(job.zones) do
        if zone.type == 'stash' then
            local stashId = ('jobcreator_%s_%s'):format(job.name, zone.type)
            local ok, err = pcall(function()
                exports.ox_inventory:RegisterStash(stashId, ('%s Stash'):format(job.label), 100, 250000, false, nil)
            end)

            if not ok then
                print(('[%s] Failed to register stash %s: %s'):format(RESOURCE_NAME, stashId, err))
            end
        end
    end
end

RegisterNetEvent('lunar-jobcreator:server:saveJob', function(payload)
    local src = source

    if type(payload) ~= 'table' then
        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 97, 97 },
            multiline = false,
            args = { 'JobCreator', 'Payload non valido.' }
        })
        return
    end

    local job, errorMessage = normalizeJob(payload)
    if not job then
        TriggerClientEvent('chat:addMessage', src, {
            color = { 255, 97, 97 },
            multiline = false,
            args = { 'JobCreator', errorMessage }
        })
        return
    end

    local mode = upsertJob(job)
    persistJobs()
    registerStashesForJob(job)

    TriggerClientEvent('chat:addMessage', src, {
        color = { 122, 255, 146 },
        multiline = false,
        args = {
            'JobCreator',
            ('Job "%s" %s e salvato lato server. Totale jobs: %s'):format(job.label, mode == 'created' and 'creato' or 'aggiornato', #cache.jobs)
        }
    })
end)

CreateThread(function()
    loadJobs()
    print(('[%s] Loaded %s jobs from %s'):format(RESOURCE_NAME, #cache.jobs, DATA_PATH))
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    for _, job in ipairs(cache.jobs) do
        registerStashesForJob(job)
    end
end)
