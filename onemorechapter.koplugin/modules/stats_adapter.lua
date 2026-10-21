local StatsAdapter = {}

local function finite_positive(value)
    value = tonumber(value)
    if not value or value ~= value or value <= 0 or value == math.huge then
        return nil
    end
    return value
end

function StatsAdapter.getPace(reader_ui, settings)
    local manual_pace = settings and finite_positive(settings.manual_seconds_per_page)
    if settings and settings.pace_source == "manual" then
        if manual_pace then
            return {
                seconds_per_page = manual_pace,
                sample_count = 0,
                confidence = "low",
                source = "manual",
            }
        end
        return nil, "manual_pace_unset"
    end

    local statistics = reader_ui and reader_ui.statistics
    local stats_settings = statistics and statistics.settings
    local average = statistics and finite_positive(statistics.avg_time)
    local samples = statistics and tonumber(statistics.book_read_pages) or 0
    if not samples or samples ~= samples or samples < 0 then
        samples = 0
    end

    if statistics and stats_settings and stats_settings.is_enabled ~= false and average and samples > 0 then
        local confidence
        if samples >= 50 then
            confidence = "high"
        elseif samples >= 20 then
            confidence = "medium"
        else
            confidence = "low"
        end
        return {
            seconds_per_page = average,
            sample_count = samples,
            confidence = confidence,
            source = "koreader_statistics",
        }
    end

    if manual_pace then
        return {
            seconds_per_page = manual_pace,
            sample_count = 0,
            confidence = "low",
            source = "manual",
        }
    end

    return nil, "pace_unavailable"
end

return StatsAdapter
