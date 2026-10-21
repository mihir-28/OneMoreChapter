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

function ChapterAdapter.read(reader_ui)
    if not reader_ui or not reader_ui.document or not reader_ui.toc then
        return nil, "reader_unavailable"
    end

    local document = reader_ui.document
    local toc = reader_ui.toc
    local current_page = call(reader_ui, "getCurrentPage")
    local page_count = call(document, "getPageCount")
    if type(current_page) ~= "number" or type(page_count) ~= "number" then
        return nil, "position_unavailable"
    end

    if type(toc.fillToc) ~= "function" or type(toc.getTocTicksFlattened) ~= "function" then
        return nil, "toc_api_unavailable"
    end
    if not pcall(toc.fillToc, toc) then
        return nil, "toc_unavailable"
    end

    local ticks = call(toc, "getTocTicksFlattened", true)
    if type(ticks) ~= "table" or #ticks == 0 then
        return nil, "toc_empty"
    end

    local boundaries = {}
    local seen_pages = {}
    for _, page in ipairs(ticks) do
        if type(page) == "number" and page > current_page and page <= page_count and not seen_pages[page] then
            seen_pages[page] = true
            local title = call(toc, "getTocTitleByPage", page)
            boundaries[#boundaries + 1] = {
                page = page,
                title = type(title) == "string" and title ~= "" and title or nil,
            }
        end
    end

    -- The last TOC entry is a chapter start, not the end of the book. Offer
    -- the document end as a final stopping point when the reader exposes it.
    if page_count > current_page and not seen_pages[page_count] then
        boundaries[#boundaries + 1] = {
            page = page_count,
            is_book_end = true,
        }
    end

    if #boundaries == 0 then
        return nil, "no_future_boundary"
    end

    table.sort(boundaries, function(left, right)
        return left.page < right.page
    end)

    local current_title = call(toc, "getTocTitleByPage", current_page)
    return {
        current_page = current_page,
        page_count = page_count,
        current_title = type(current_title) == "string" and current_title ~= "" and current_title or nil,
        boundaries = boundaries,
    }
end

return ChapterAdapter
