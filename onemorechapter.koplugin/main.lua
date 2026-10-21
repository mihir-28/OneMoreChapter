local WidgetContainer = require("ui/widget/container/widgetcontainer")
local Event = require("ui/event")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local Settings = require("modules/settings")
local UI = require("modules/ui")

local OneMoreChapter = WidgetContainer:extend{
    name = "onemorechapter",
    settings_key = Settings.KEY,
    is_doc_only = true,
}

function OneMoreChapter:init()
    self.settings = Settings.load()
    self.ui.menu:registerToMainMenu(self)
    self.header_estimate_func = function()
        if not self.settings.show_header_estimate then
            return nil
        end
        return UI.headerEstimateText(self)
    end
    self:updateHeaderEstimate()
end

function OneMoreChapter:updateHeaderEstimate()
    local listener = self.ui.crelistener
    if not listener then
        return
    end

    local registered = self.header_estimate_registered
    if self.settings.show_header_estimate and not registered then
        listener:addAdditionalHeaderContent(self.header_estimate_func)
        self.header_estimate_registered = true
    elseif not self.settings.show_header_estimate and registered then
        listener:removeAdditionalHeaderContent(self.header_estimate_func)
        self.header_estimate_registered = false
    end
    UIManager:broadcastEvent(Event:new("UpdateHeader"))
end

function OneMoreChapter:isSupportedDocument()
    local document = self.ui.document
    local file = document and document.file
    return type(file) == "string" and file:lower():match("%.epub$") ~= nil
end

function OneMoreChapter:addToMainMenu(menu_items)
    menu_items.one_more_chapter = {
        text = _("One More Chapter"),
        sorting_hint = "tools",
        enabled_func = function()
            return self:isSupportedDocument()
        end,
        callback = function()
            UI.showBudgetChooser(self)
        end,
    }

    -- KOReader's sorting_hint appends plugin items to a tab. Put this entry
    -- first in the pinned reader menu order so it stays on the first Tools page.
    local order = require("ui/elements/reader_menu_order")
    if type(order.tools) == "table" then
        for index = #order.tools, 1, -1 do
            if order.tools[index] == "one_more_chapter" then
                table.remove(order.tools, index)
            end
        end
        table.insert(order.tools, 1, "one_more_chapter")
    end
end

return OneMoreChapter
