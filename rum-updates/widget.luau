--!nonstrict

local barWidget = noctalia.widget.bar
local tooltipWidget = noctalia.widget.tooltip

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

local function render()
    local visible = updateError ~= nil or not hideWhenEmpty or count > 0
    local text = tr("bar.text.error")

    if updateError == nil then
        if count == 1 then
            text = tr("bar.text.single")
        else
            text = tr("bar.text.plural", { count = count })
        end
    end

    barWidget.render({
        visible = visible,
        icon = "download",
        text = text,
        onClick = function()
            if clickAction == "run_updater" then
                if not noctalia.commandExists("rum") then
                    noctalia.notify(tr("bar.notify.missing_rum"), "error")
                    return
                end
                if not noctalia.runInTerminal("sudo rum system-upgrade") then
                    noctalia.notify(tr("bar.notify.terminal_failed"), "error")
                end
                return
            end

            if not noctalia.commandExists("rakuos-software") then
                noctalia.notify(tr("bar.notify.missing_software_center"), "error")
                return
            end
            if not noctalia.runAsync("rakuos-software") then
                noctalia.notify(tr("bar.notify.software_center_failed"), "error")
            end
        end,
    })
end

local function renderTooltip()
    local rows = {}
    local visible = updateError ~= nil or not hideWhenEmpty or count > 0

    if updateError ~= nil then
        table.insert(rows, { key = tr("tooltip.error"), value = updateError })
    else
        table.insert(rows, {
            key = tr("tooltip.package_updates"),
            value = tostring(count),
        })

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
                value = tr("tooltip.repository", { repo = update.repo }),
            })
        end
    end

    tooltipWidget.render({ visible = visible, rows = rows })
end

noctalia.state.watch("updates", function(value)
    if type(value) ~= "table" then
        value = {}
    end

    local nextCount = #value
    if hasReceivedUpdateState and notify and nextCount > previousCount then
        noctalia.notify(tr("bar.notify.new_updates", { count = nextCount }))
    end

    stateUpdates = value
    count = nextCount
    previousCount = nextCount
    hasReceivedUpdateState = true
    render()
    renderTooltip()
end)

noctalia.state.watch("update_error", function(value)
    if type(value) ~= "string" or value == "" then
        updateError = nil
    else
        updateError = value
    end
    render()
    renderTooltip()
end)

render()
renderTooltip()
