local WidgetContainer = require("ui/widget/container/widgetcontainer")
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
            UI.showBudgetChooser(self)
        end,
    }
end

return OneMoreChapter
