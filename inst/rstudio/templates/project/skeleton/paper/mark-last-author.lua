-- Annotates the YAML author list (both author: and by-author: that
-- Quarto produces from it) so the title.tex partial can detect the
-- first and last author and join them with proper Oxford-comma
-- punctuation:
--   1 author:  "A"
--   2 authors: "A and B"
--   3+ authors: "A, B, and C"

local function mark(list)
  if list == nil then return end
  local n = #list
  if n == 0 then return end
  list[1]["is-first"] = true
  list[n]["is-last"] = true              -- ALWAYS mark the last author, even if it is also the first
  if n > 1 then
    list[n-1]["next-is-last"] = true
    if n == 2 then
      list[n]["is-only-coauthor"] = true
    end
  end
end

function Meta(meta)
  mark(meta.author)
  mark(meta["by-author"])
  return meta
end
