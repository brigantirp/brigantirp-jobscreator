local RESOURCE_NAME = GetCurrentResourceName()
local DATA_PATH = 'data/jobs.json'
local QBX_JOBS_CONVAR = 'jobscreator_qbx_jobs_path'

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

local function escapeLuaPattern(value)
    return value:gsub('([^%w])', '%%%1')
end

local function quoteLuaString(value)
    return ('"%s"'):format(tostring(value):gsub('\\', '\\\\'):gsub('"', '\\"'))
end

local function getResourceFilePath(resourceName, filePath)
    local resourcePath = normalizeString(GetResourcePath(resourceName), nil)
    if not resourcePath then
        return nil
    end

    return ('%s/%s'):format(resourcePath:gsub('\\', '/'), filePath)
end

local function resolveQbxJobsPath()
    local configuredPath = normalizeString(GetConvar(QBX_JOBS_CONVAR, ''), '')
    if configuredPath and configuredPath ~= '' then
        return {
            mode = 'absolute',
            path = configuredPath
        }
    end

    if GetResourceState('qbx_core') == 'missing' then
        return nil, 'La resource qbx_core non è stata trovata. Avviala o configura jobscreator_qbx_jobs_path con il path assoluto del jobs.lua.'
    end

    return {
        mode = 'resource',
        resource = 'qbx_core',
        file = 'shared/jobs.lua'
    }
end

local function buildQbxJobBlock(job)
    local gradesLines = {}

    for index, grade in ipairs(job.grades) do
        gradesLines[#gradesLines + 1] = (
            "            ['%s'] = { name = %s, payment = %s, isboss = %s },"
        ):format(index - 1, quoteLuaString(grade.name), math.max(0, math.floor(grade.salary or 0)), grade.boss and 'true' or 'false')
    end

    if #gradesLines == 0 then
        gradesLines[1] = "            ['0'] = { name = \"grade_0\", payment = 0, isboss = false },"
    end

    local zoneLines = {}
    for _, zone in ipairs(job.zones) do
        zoneLines[#zoneLines + 1] = ('            { type = %s, coords = %s },'):format(quoteLuaString(zone.type), quoteLuaString(zone.coords))
    end

    local zonesBlock = #zoneLines > 0 and table.concat(zoneLines, '\n') or '            -- nessuna zona configurata'

    return ([[    -- JOBSCREATOR:BEGIN %s
    [%s] = {
        label = %s,
        type = %s,
        defaultDuty = true,
        offDutyPay = false,
        description = %s,
        icon = %s,
        color = %s,
        webhook = %s,
        zones = {
%s
        },
        options = {
            canHandcuff = %s,
            canImpound = %s,
            dutySystem = %s,
            billingEnabled = %s,
            whitelistOnly = %s,
        },
        grades = {
%s
        },
    },
    -- JOBSCREATOR:END %s]]):format(
        job.name,
        quoteLuaString(job.name),
        quoteLuaString(job.label),
        quoteLuaString(job.type),
        quoteLuaString(job.description),
        quoteLuaString(job.icon),
        quoteLuaString(job.color),
        quoteLuaString(job.webhook),
        zonesBlock,
        job.options.canHandcuff and 'true' or 'false',
        job.options.canImpound and 'true' or 'false',
        job.options.dutySystem and 'true' or 'false',
        job.options.billingEnabled and 'true' or 'false',
        job.options.whitelistOnly and 'true' or 'false',
        table.concat(gradesLines, '\n'),
        job.name
    )
end

local function persistJobToQbxCore(job)
    local target, resolveErr = resolveQbxJobsPath()
    if not target then
        return false, resolveErr or ('Impossibile risolvere il path di qbx_core/shared/jobs.lua. Configura +set %s <path_assoluto>.'):format(QBX_JOBS_CONVAR)
    end

    local content
    local displayPath
    local filesystemPath

    if target.mode == 'resource' then
        content = LoadResourceFile(target.resource, target.file)
        displayPath = ('%s/%s'):format(target.resource, target.file)
        filesystemPath = getResourceFilePath(target.resource, target.file)

        if (not content or content == '') and filesystemPath then
            local readHandle, readErr = io.open(filesystemPath, 'r')
            if readHandle then
                content = readHandle:read('*a')
                readHandle:close()
                displayPath = ('%s (filesystem)'):format(filesystemPath)
            else
                return false, ('Impossibile leggere %s tramite LoadResourceFile e fallback filesystem fallito (%s).'):format(displayPath, readErr or 'errore sconosciuto')
            end
        elseif not content or content == '' then
            return false, ('Impossibile leggere %s tramite LoadResourceFile.'):format(displayPath)
        end
    else
        displayPath = target.path
        filesystemPath = target.path
        local readHandle, readErr = io.open(displayPath, 'r')
        if not readHandle then
            return false, ('Impossibile leggere %s: %s'):format(displayPath, readErr or 'errore sconosciuto')
        end

        content = readHandle:read('*a')
        readHandle:close()
    end

    local escapedName = escapeLuaPattern(job.name)
    local markerPattern = '%s*%-%- JOBSCREATOR:BEGIN ' .. escapedName .. '.-%-%- JOBSCREATOR:END ' .. escapedName .. '\n?'
    content = content:gsub(markerPattern, '')

    local closingIndex = content:find('}%s*$')
    if not closingIndex then
        return false, ('Il file %s non sembra un jobs.lua valido (manca la parentesi finale).'):format(displayPath)
    end

    local block = buildQbxJobBlock(job)
    local updatedContent = content:sub(1, closingIndex - 1)
        .. '\n\n'
        .. block
        .. '\n'
        .. content:sub(closingIndex)

    if filesystemPath then
        local writeHandle, writeErr = io.open(filesystemPath, 'w')
        if not writeHandle then
            if target.mode ~= 'resource' then
                return false, ('Impossibile scrivere %s: %s'):format(displayPath, writeErr or 'errore sconosciuto')
            end
        else
            writeHandle:write(updatedContent)
            writeHandle:close()

            return true, ('%s (filesystem)'):format(filesystemPath)
        end
    end

    if target.mode == 'resource' then
        local saved = SaveResourceFile(target.resource, target.file, updatedContent, -1)
        if saved then
            return true, displayPath
        end

        return false, ('Impossibile scrivere %s tramite filesystem e SaveResourceFile ha restituito false.'):format(displayPath)
    end

    return false, ('Impossibile determinare una strategia di scrittura valida per %s.'):format(displayPath)
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

RegisterNetEvent('brigantirp-jobscreator:server:saveJob', function(payload)
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
    local qbxSaved, qbxResult = persistJobToQbxCore(job)
    registerStashesForJob(job)

    TriggerClientEvent('chat:addMessage', src, {
        color = qbxSaved and { 122, 255, 146 } or { 255, 170, 80 },
        multiline = false,
        args = {
            'JobCreator',
            qbxSaved
                and ('Job "%s" %s. JSON aggiornato + jobs.lua sincronizzato (%s). Totale jobs: %s'):format(job.label, mode == 'created' and 'creato' or 'aggiornato', qbxResult, #cache.jobs)
                or ('Job "%s" salvato solo su JSON. Sync jobs.lua fallita: %s'):format(job.label, qbxResult)
        }
    })

    if not qbxSaved then
        print(('[%s] qbx_core sync failed for job %s: %s'):format(RESOURCE_NAME, job.name, qbxResult))
    end
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
