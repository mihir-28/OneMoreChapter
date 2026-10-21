local Estimator = {}

local UNCERTAINTY = {
    high = 0.20,
    medium = 0.35,
    low = 0.50,
}

function Estimator.estimate(page_count, pace)
    if type(page_count) ~= "number" or page_count < 0 or not pace then
        return nil
    end

    local seconds_per_page = tonumber(pace.seconds_per_page)
    if not seconds_per_page or seconds_per_page <= 0 then
        return nil
    end

    local expected_seconds = page_count * seconds_per_page
    local margin = UNCERTAINTY[pace.confidence] or UNCERTAINTY.low
    return {
        pages = page_count,
        expected_seconds = expected_seconds,
        minimum_seconds = expected_seconds * (1 - margin),
        maximum_seconds = expected_seconds * (1 + margin),
        confidence = pace.confidence or "low",
        sample_count = pace.sample_count or 0,
        source = pace.source,
    }
end

function Estimator.recommend(boundaries, current_page, budget_minutes, pace, safety_buffer)
    if type(boundaries) ~= "table" or type(current_page) ~= "number" or not pace then
        return nil
    end

    local budget_seconds = budget_minutes * 60
    local buffer = tonumber(safety_buffer) or 0.10
    buffer = math.max(0, math.min(buffer, 0.50))
    local safe_limit = budget_seconds * (1 - buffer)
    local recommendation
    local next_boundary

    for _, boundary in ipairs(boundaries) do
        local estimate = Estimator.estimate(boundary.page - current_page, pace)
        if estimate then
            local result = {
                boundary = boundary,
                estimate = estimate,
            }
            if not next_boundary then
                next_boundary = result
            end
            if estimate.maximum_seconds <= safe_limit then
                recommendation = result
            end
        end
    end

    local candidate = recommendation or next_boundary
    if not candidate then
        return nil
    end

    local estimate = candidate.estimate
    local status
    if estimate.maximum_seconds <= budget_seconds then
        status = "likely"
    elseif estimate.minimum_seconds <= budget_seconds then
        status = "tight"
    else
        status = "unlikely"
    end

    return {
        recommendation = recommendation,
        next_boundary = next_boundary,
        status = status,
        budget_minutes = budget_minutes,
        safety_buffer = buffer,
    }
end

return Estimator
