local Settings = {}

Settings.KEY = "onemorechapter"
Settings.DEFAULTS = {
    safety_buffer = 0.10,
    pace_source = "auto",
    manual_seconds_per_page = nil,
    last_budget_minutes = 20,
}

function Settings.load()
    local saved = G_reader_settings:readSetting(Settings.KEY, {}) or {}
    local result = {}
    for key, value in pairs(Settings.DEFAULTS) do
        result[key] = value
    end
    for key, value in pairs(saved) do
        result[key] = value
    end
    return result
end

function Settings.save(settings)
    G_reader_settings:saveSetting(Settings.KEY, settings)
end

return Settings
