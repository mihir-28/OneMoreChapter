local ButtonDialog = require("ui/widget/buttondialog")
local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local ChapterAdapter = require("modules/chapter_adapter")
local Estimator = require("modules/estimator")
local Settings = require("modules/settings")
local StatsAdapter = require("modules/stats_adapter")

local UI = {}
local BUDGETS = { 10, 15, 20, 30 }

local function showMessage(text)
    UIManager:show(InfoMessage:new{ text = text })
end

local function rangeText(estimate)
    local minimum = math.max(1, math.floor(estimate.minimum_seconds / 60))
    local maximum = math.max(minimum, math.ceil(estimate.maximum_seconds / 60))
    return minimum .. "-" .. maximum .. " " .. _("min")
end

local function confidenceText(confidence)
    local labels = {
        high = _("High"),
        medium = _("Medium"),
        low = _("Low"),
    }
    return labels[confidence] or labels.low
end

local function boundaryTitle(boundary)
    if boundary.is_book_end then
        return _("End of book")
    end
    return boundary.title or _("Untitled chapter")
end

local function describeContext(chapters, pace)
    local lines = {}
    lines[#lines + 1] = _("Current chapter") .. ": " .. (chapters.current_title or _("Unknown"))

    local current_boundary = chapters.boundaries[1]
    local current_estimate = pace and Estimator.estimate(current_boundary.page - chapters.current_page, pace)
    lines[#lines + 1] = _("Time to chapter end") .. ": "
        .. (current_estimate and rangeText(current_estimate) or _("Set a reading pace to estimate"))

    local next_boundary = chapters.boundaries[2]
    if next_boundary then
        local chapter_pages = next_boundary.page - current_boundary.page
        local next_estimate = pace and Estimator.estimate(chapter_pages, pace)
        lines[#lines + 1] = _("Next chapter") .. ": " .. boundaryTitle(next_boundary)
        lines[#lines + 1] = _("Next chapter time") .. ": "
            .. (next_estimate and rangeText(next_estimate) or _("Unavailable"))
    end

    return table.concat(lines, "\n")
end

local function readState(plugin)
    local chapters, chapter_error = ChapterAdapter.read(plugin.ui)
    if not chapters then
        return nil, chapter_error
    end
    return {
        chapters = chapters,
        pace = StatsAdapter.getPace(plugin.ui, plugin.settings),
    }
end

local function promptManualPace(plugin, on_saved)
    local dialog
    dialog = InputDialog:new{
        title = _("Set manual reading pace"),
        description = _("Enter average seconds spent per rendered page."),
        input = plugin.settings.manual_seconds_per_page and tostring(plugin.settings.manual_seconds_per_page) or "",
        input_hint = _("Seconds per page"),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function()
                        UIManager:close(dialog)
                    end,
                },
                {
                    text = _("Save"),
                    is_enter_default = true,
                    callback = function()
                        local seconds_per_page = tonumber(dialog:getInputText())
                        if not seconds_per_page or seconds_per_page < 1 or seconds_per_page > 3600 then
                            showMessage(_("Enter a value from 1 to 3600 seconds per page."))
                            return
                        end
                        plugin.settings.manual_seconds_per_page = seconds_per_page
                        plugin.settings.pace_source = "manual"
                        Settings.save(plugin.settings)
                        UIManager:close(dialog)
                        if on_saved then
                            on_saved()
                        end
                    end,
                },
            },
        },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

local function promptSafetyBuffer(plugin)
    local dialog
    dialog = InputDialog:new{
        title = _("Safety buffer"),
        description = _("Reserve part of your budget before recommending a chapter. Enter 0 to 50 percent."),
        input = tostring(math.floor((plugin.settings.safety_buffer or 0.10) * 100)),
        input_hint = _("Percent"),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function()
                        UIManager:close(dialog)
                    end,
                },
                {
                    text = _("Save"),
                    is_enter_default = true,
                    callback = function()
                        local percent = tonumber(dialog:getInputText())
                        if not percent or percent < 0 or percent > 50 then
                            showMessage(_("Enter a value from 0 to 50 percent."))
                            return
                        end
                        plugin.settings.safety_buffer = percent / 100
                        Settings.save(plugin.settings)
                        UIManager:close(dialog)
                        UI.showBudgetChooser(plugin)
                    end,
                },
            },
        },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

local function showResult(plugin, budget_minutes)
    local state = readState(plugin)
    if not state then
        showMessage(_("Chapter boundary unavailable. This EPUB does not expose a usable table of contents."))
        return
    end
    if not state.pace then
        promptManualPace(plugin, function()
            showResult(plugin, budget_minutes)
        end)
        return
    end

    local plan = Estimator.recommend(
        state.chapters.boundaries,
        state.chapters.current_page,
        budget_minutes,
        state.pace,
        plugin.settings.safety_buffer
    )
    if not plan then
        showMessage(_("Could not estimate a stopping point for this EPUB."))
        return
    end

    local selected = plan.recommendation
    local target = selected or plan.next_boundary
    local status = {
        likely = _("Likely"),
        tight = _("Tight"),
        unlikely = _("Unlikely"),
    }
    local lines = {
        _("Time budget") .. ": " .. budget_minutes .. " min",
        _("Confidence") .. ": " .. confidenceText(target.estimate.confidence),
        _("Estimate") .. ": " .. rangeText(target.estimate),
    }

    if selected then
        lines[#lines + 1] = _("Stop before") .. ": " .. boundaryTitle(target.boundary)
        lines[#lines + 1] = status[plan.status] .. _(" fit within your time budget.")
    else
        lines[#lines + 1] = _("No chapter boundary fits within the time budget buffer.")
        lines[#lines + 1] = _("Next boundary") .. ": " .. boundaryTitle(target.boundary)
        lines[#lines + 1] = status[plan.status] .. _(" to finish within your time budget.")
    end

    lines[#lines + 1] = _("No pages will be skipped or moved automatically.")
    if target.estimate.sample_count > 0 and target.estimate.confidence == "low" then
        lines[#lines + 1] = _("Provisional: ") .. target.estimate.sample_count .. _(" recorded pages used for pace.")
    end
    if target.estimate.source == "manual" then
        lines[#lines + 1] = _("Using your manual seconds-per-page setting.")
    end

    showMessage(table.concat(lines, "\n"))
end

local function chooseBudget(plugin, budget_minutes)
    plugin.settings.last_budget_minutes = budget_minutes
    Settings.save(plugin.settings)
    showResult(plugin, budget_minutes)
end

local function promptCustomBudget(plugin)
    local dialog
    dialog = InputDialog:new{
        title = _("Custom time budget"),
        description = _("Enter a budget from 1 to 480 minutes."),
        input = tostring(plugin.settings.last_budget_minutes or 20),
        input_hint = _("Minutes"),
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function()
                        UIManager:close(dialog)
                    end,
                },
                {
                    text = _("Continue"),
                    is_enter_default = true,
                    callback = function()
                        local budget = tonumber(dialog:getInputText())
                        if not budget or budget < 1 or budget > 480 or budget % 1 ~= 0 then
                            showMessage(_("Enter a whole number from 1 to 480 minutes."))
                            return
                        end
                        UIManager:close(dialog)
                        chooseBudget(plugin, math.floor(budget))
                    end,
                },
            },
        },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

function UI.showBudgetChooser(plugin)
    local state, chapter_error = readState(plugin)
    if not state then
        local message = chapter_error == "no_future_boundary" and _("No later chapter boundary was found in this EPUB.")
            or _("Chapter boundary unavailable. This EPUB does not expose a usable table of contents.")
        showMessage(message)
        return
    end

    local buttons = {}
    for index = 1, #BUDGETS, 2 do
        local row = {}
        for offset = 0, 1 do
            local budget = BUDGETS[index + offset]
            if budget then
                local selected_budget = budget
                row[#row + 1] = {
                    text = selected_budget .. " " .. _("min"),
                    callback = function()
                        UIManager:close(plugin.budget_dialog)
                        chooseBudget(plugin, selected_budget)
                    end,
                }
            end
        end
        buttons[#buttons + 1] = row
    end
    buttons[#buttons + 1] = {
        {
            text = _("Custom budget"),
            callback = function()
                UIManager:close(plugin.budget_dialog)
                promptCustomBudget(plugin)
            end,
        },
    }
    buttons[#buttons + 1] = {
        {
            text = _("Set manual pace"),
            callback = function()
                UIManager:close(plugin.budget_dialog)
                promptManualPace(plugin, function()
                    UI.showBudgetChooser(plugin)
                end)
            end,
        },
    }
    buttons[#buttons + 1] = {
        {
            text = _("Set safety buffer"),
            callback = function()
                UIManager:close(plugin.budget_dialog)
                promptSafetyBuffer(plugin)
            end,
        },
    }
    buttons[#buttons + 1] = {
        {
            text = _("Use KOReader automatic pace"),
            enabled_func = function()
                return plugin.settings.pace_source == "manual"
            end,
            callback = function()
                plugin.settings.pace_source = "auto"
                Settings.save(plugin.settings)
                UIManager:close(plugin.budget_dialog)
                UI.showBudgetChooser(plugin)
            end,
        },
    }

    local title = describeContext(state.chapters, state.pace) .. "\n\n" .. _("Choose your time budget")
    plugin.budget_dialog = ButtonDialog:new{
        title = title,
        title_align = "left",
        buttons = buttons,
    }
    UIManager:show(plugin.budget_dialog)
end

return UI
