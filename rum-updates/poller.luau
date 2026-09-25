--!nonstrict

local updates = {}
local isPolling = false

local interval = tonumber(noctalia.getConfig("interval")) or 300
interval = math.max(60, math.min(interval, 86400))
noctalia.setUpdateInterval(interval * 1000)

noctalia.state.set("updates", updates)
noctalia.state.set("update_error", nil)

local function trim(value)
    return noctalia.string.trim(value or "")
end

local function cleanError(value)
    local message = trim(value)
    if message == "" then
        return noctalia.tr("poller.error.exit", { code = "unknown" })
    end
    if #message > 500 then
        return string.sub(message, 1, 497) .. "..."
    end
    return message
end

local function findJson(stdout)
    local candidate = nil
    for line in string.gmatch(stdout or "", "[^\r\n]+") do
        local text = trim(line)
        if string.sub(text, 1, 1) == "{" and string.sub(text, -1) == "}" then
            candidate = text
        end
    end
    return candidate
end

local function decodeUpdates(stdout)
    local text = findJson(stdout)
    if text == nil then
        return nil, noctalia.tr("poller.error.invalid_json")
    end

    local decoded, decodeError = noctalia.json.decode(text)
    if decoded == nil or decodeError ~= nil then
        return nil, noctalia.tr("poller.error.invalid_json")
    end
    if type(decoded) ~= "table" or type(decoded.updates) ~= "table" then
        return nil, noctalia.tr("poller.error.invalid_payload")
    end

    local parsed = {}
    for _, update in ipairs(decoded.updates) do
        if type(update) ~= "table"
            or type(update.name) ~= "string"
            or type(update.current_version) ~= "string"
            or type(update.version) ~= "string"
            or type(update.arch) ~= "string"
            or type(update.repo) ~= "string" then
            return nil, noctalia.tr("poller.error.invalid_payload")
        end

        table.insert(parsed, {
            name = update.name,
            current_version = update.current_version,
            version = update.version,
            arch = update.arch,
            repo = update.repo,
        })
    end

    table.sort(parsed, function(left, right)
        if left.name == right.name then
            if left.arch == right.arch then
                return left.repo < right.repo
            end
            return left.arch < right.arch
        end
        return left.name < right.name
    end)

    return parsed
end

local function showError(message)
    noctalia.state.set("update_error", cleanError(message))
end

local function refresh()
    if isPolling then
        return
    end

    if not noctalia.commandExists("rum") then
        updates = {}
        noctalia.state.set("updates", updates)
        showError(noctalia.tr("poller.error.missing_rum"))
        return
    end

    isPolling = true
    local started = noctalia.runAsync("rum check-upgrade --json", function(result)
        isPolling = false

        if result.exitCode ~= 0 then
            showError(result.stderr)
            return
        end

        local parsed, parseError = decodeUpdates(result.stdout)
        if parsed == nil then
            showError(parseError)
            return
        end

        updates = parsed
        noctalia.state.set("updates", updates)
        noctalia.state.set("update_error", nil)
    end)

    if not started then
        isPolling = false
        updates = {}
        noctalia.state.set("updates", updates)
        showError(noctalia.tr("poller.error.launch_failed"))
    end
end

function update()
    refresh()
end

refresh()
