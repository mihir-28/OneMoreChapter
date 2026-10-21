local ChapterAdapter = {}

local function call(object, method_name, ...)
    if not object or type(object[method_name]) ~= "function" then
        return nil
    end
    local ok, result = pcall(object[method_name], object, ...)
    if ok then
        return result
    end
end

local function cleanTitle(toc, title)
    title = call(toc, "cleanUpTocTitle", title)
    return type(title) == "string" and title ~= "" and title or nil
end

function ChapterAdapter.read(reader_ui)
    if not reader_ui or not reader_ui.document or not reader_ui.toc then
        return nil, "reader_unavailable"
    end

    local document = reader_ui.document
    local toc = reader_ui.toc
    local current_page = call(reader_ui, "getCurrentPage")
    local page_count = call(document, "getPageCount")
    local current_position = call(document, "getCurrentPos")
    if type(current_page) ~= "number" or type(page_count) ~= "number" then
        return nil, "position_unavailable"
    end

    if type(toc.fillToc) ~= "function" or type(toc.getTocTicksFlattened) ~= "function" then
        return nil, "toc_api_unavailable"
    end
    if not pcall(toc.fillToc, toc) then
        return nil, "toc_unavailable"
    end

    local toc_entries = toc.toc
    local ticks = call(toc, "getTocTicksFlattened", true)
    if (type(toc_entries) ~= "table" or #toc_entries == 0)
        and (type(ticks) ~= "table" or #ticks == 0) then
        return nil, "toc_empty"
    end

    local boundaries = {}
    local ignored_levels = toc.toc_ticks_ignored_levels or {}
    local filter_ignored_levels = next(ignored_levels) ~= nil and toc.toc_chapter_navigation_bind_to_ticks
    local current_index
    if type(current_position) == "string" and type(toc.getTocIndexByPage) == "function" then
        current_index = call(toc, "getTocIndexByPage", current_position, filter_ignored_levels)
    end

    if type(current_index) == "number" and type(toc_entries) == "table" then
        -- Preserve TOC order even when several chapter starts share one rendered page.
        for index = current_index + 1, #toc_entries do
            local entry = toc_entries[index]
            local is_ignored = filter_ignored_levels and ignored_levels[entry.depth]
            local page = entry.page
            if not is_ignored and type(page) == "number" and page >= current_page and page <= page_count then
                boundaries[#boundaries + 1] = {
                    page = page,
                    title = cleanTitle(toc, entry.title),
                    xpointer = entry.xpointer,
                }
            end
        end
    else
        -- Page-only fallback for reader builds without usable XPointer lookup.
        if type(ticks) ~= "table" then
            return nil, "toc_unavailable"
        end
        for _, page in ipairs(ticks) do
            if type(page) == "number" and page > current_page and page <= page_count then
                boundaries[#boundaries + 1] = {
                    page = page,
                    title = cleanTitle(toc, call(toc, "getTocTitleByPage", page)),
                }
            end
        end
    end

    -- The last TOC entry is a chapter start, not the end of the book. Offer
    -- the document end as a final stopping point when the reader exposes it.
    local has_book_end = false
    for _, boundary in ipairs(boundaries) do
        if boundary.page == page_count then
            has_book_end = true
            break
        end
    end
    if page_count > current_page and not has_book_end then
        boundaries[#boundaries + 1] = {
            page = page_count,
            is_book_end = true,
        }
    end

    if #boundaries == 0 then
        return nil, "no_future_boundary"
    end

    local current_title = cleanTitle(toc, call(toc, "getTocTitleByPage", current_position or current_page))
    if not current_title and type(current_index) == "number" and type(toc_entries) == "table" then
        current_title = cleanTitle(toc, toc_entries[current_index] and toc_entries[current_index].title)
    end
    return {
        current_page = current_page,
        page_count = page_count,
        current_title = current_title,
        boundaries = boundaries,
    }
end

return ChapterAdapter
