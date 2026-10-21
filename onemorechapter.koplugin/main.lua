local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

local OneMoreChapter = WidgetContainer:extend{
    name = "onemorechapter",
    is_doc_only = true,
}

local function collectMethods(object)
    local names = {}
    local seen_tables = {}
    local current = object

    while type(current) == "table" and not seen_tables[current] do
        seen_tables[current] = true
        for name, value in pairs(current) do
            if type(name) == "string" and type(value) == "function" then
                names[name] = true
            end
        end
        local metatable = getmetatable(current)
        current = type(metatable) == "table" and metatable.__index or nil
    end

    local result = {}
    for name in pairs(names) do
        result[#result + 1] = name
    end
    table.sort(result)
    return result
end

local function logMethods(label, object)
    local methods = collectMethods(object)
    logger.info("OneMoreChapter API", label, table.concat(methods, ","))
end

local function safeCall(object, method_name, ...)
    if not object or type(object[method_name]) ~= "function" then
        return nil
    end
    local ok, result = pcall(object[method_name], object, ...)
    if ok then
        return result
    end
    logger.warn("OneMoreChapter API call failed", method_name, result)
    return nil
end

function OneMoreChapter:init()
    self.ui.menu:registerToMainMenu(self)
end

function OneMoreChapter:isSupportedDocument()
    local document = self.ui.document
    local file = document and document.file
    return type(file) == "string" and file:lower():match("%.epub$") ~= nil
end

function OneMoreChapter:addToMainMenu(menu_items)
    menu_items.one_more_chapter = {
        text = _("One More Chapter"),
        sorting_hint = "more_tools",
        enabled_func = function()
            return self:isSupportedDocument()
        end,
        callback = function()
            self:showDiagnostics()
        end,
    }
end

function OneMoreChapter:showDiagnostics()
    local document = self.ui.document
    local toc = self.ui.toc
    local statistics = self.ui.statistics

    logMethods("reader", self.ui)
    logMethods("document", document)
    logMethods("toc", toc)
    logMethods("statistics", statistics)

    if toc then
        safeCall(toc, "fillToc")
    end

    local page = safeCall(self.ui, "getCurrentPage")
    local page_count = safeCall(document, "getPageCount")
    local current_position = safeCall(document, "getCurrentPos")
    local chapter_index = page and safeCall(toc, "getTocIndexByPage", page, true) or nil
    local current_title = page and safeCall(toc, "getTocTitleByPage", page) or nil
    local next_chapter_page = page and safeCall(toc, "getNextChapter", page) or nil
    local next_title = next_chapter_page and safeCall(toc, "getTocTitleByPage", next_chapter_page) or nil
    local estimate

    if next_chapter_page and page and statistics then
        estimate = safeCall(statistics, "getTimeForPages", next_chapter_page - page)
    end

    local file = document and document.file or _("Unavailable")
    local text = _("API diagnostic")
        .. "\n\n" .. _("Document") .. ": " .. tostring(file)
        .. "\n" .. _("Position") .. ": " .. tostring(current_position or _("Unavailable"))
        .. "\n" .. _("Page") .. ": " .. tostring(page or _("Unavailable"))
        .. " / " .. tostring(page_count or _("Unavailable"))
        .. "\n" .. _("Chapter index") .. ": " .. tostring(chapter_index or _("Unavailable"))
        .. "\n" .. _("Current chapter") .. ": " .. tostring(current_title and current_title ~= "" and current_title or _("Unavailable"))
        .. "\n" .. _("Next chapter") .. ": " .. tostring(next_title and next_title ~= "" and next_title or _("Unavailable"))
        .. "\n" .. _("Next boundary page") .. ": " .. tostring(next_chapter_page or _("Unavailable"))
        .. "\n" .. _("KOReader estimate") .. ": " .. tostring(estimate or _("Unavailable"))

    UIManager:show(InfoMessage:new{
        text = _("One More Chapter") .. "\n\n" .. text,
    })
end

return OneMoreChapter
