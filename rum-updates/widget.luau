--!nonstrict

local hideWhenEmpty = noctalia.getConfig("hide_when_empty") == true
local notify = noctalia.getConfig("notify") == true
local clickAction = noctalia.getConfig("click_action") or "open_software_center"
if clickAction ~= "run_updater" then
    clickAction = "open_software_center"
end

local stateUpdates = noctalia.state.get("updates")
if type(stateUpdates) ~= "table" then
    stateUpdates = {}
end

local stateError = noctalia.state.get("update_error")
if type(stateError) ~= "string" or stateError == "" then
    stateError = nil
end

local previousCount = #stateUpdates
local hasReceivedUpdateState = false
local count = #stateUpdates
local updateError = stateError

local function renderTooltip()
    if updateError ~= nil then
        barWidget.setTooltip({
            key = noctalia.tr("tooltip.error"),
            value = updateError,
        })
        return
    end

    local rows = {
        {
            key = noctalia.tr("tooltip.package_updates"),
            value = tostring(count),
        },
    }

    for _, update in ipairs(stateUpdates) do
        local name = string.format("%s.%s", update.name, update.arch)
        local change = string.format(
            "%s → %s",
            update.current_version,
            update.version
        )
        table.insert(rows, { key = name, value = change })
        table.insert(rows, {
            key = "",
            value = noctalia.tr("tooltip.repository", { repo = update.repo }),
        })
    end

    barWidget.setTooltip(rows)
end

local function render()
    local visible = updateError ~= nil or not hideWhenEmpty or count > 0
    local text = noctalia.tr("bar.text.error")

    if updateError == nil then
        if count == 1 then
            text = noctalia.tr("bar.text.single")
        else
            text = noctalia.tr("bar.text.plural", { count = count })
        end
    end

    local container = barWidget.isVertical() and ui.column or ui.row
    barWidget.render(container({
        gap = 6,
        align = "center",
        visible = visible,
    }, {
        ui.glyph({ name = "download", size = 14 }),
        ui.label({ text = text }),
    }))

    renderTooltip()
end

noctalia.state.watch("updates", function(value)
    if type(value) ~= "table" then
        value = {}
    end

    local nextCount = #value
    if hasReceivedUpdateState and notify and nextCount > previousCount then
        noctalia.notify(
            noctalia.tr("bar.notify.new_updates.title"),
            noctalia.tr("bar.notify.new_updates.description", { count = nextCount })
        )
    end

    stateUpdates = value
    count = nextCount
    previousCount = nextCount
    hasReceivedUpdateState = true
    render()
end)

noctalia.state.watch("update_error", function(value)
    if type(value) ~= "string" or value == "" then
        updateError = nil
    else
        updateError = value
    end
    render()
end)

function onClick()
    if clickAction == "run_updater" then
        if not noctalia.commandExists("rum") then
            noctalia.notifyError("RUM Updates", noctalia.tr("bar.notify.missing_rum"))
            return
        end
        noctalia.runInTerminal("sudo rum system-upgrade")
        return
    end

    if not noctalia.commandExists("rakuos-software") then
        noctalia.notifyError(
            "RUM Updates",
            noctalia.tr("bar.notify.missing_software_center")
        )
        return
    end
    noctalia.runAsync("rakuos-software")
end

render()
