-- qkit-cv Pandoc Lua filter.
--
-- Rewrites semantic divs into the CV's specific LaTeX patterns so users
-- can write mostly-pure markdown CVs. Recognized divs:
--
--   ::: {.cv-entries}            bullet list of `- key | value` items,
--                                italic col 1, default row gap 15pt
--   ::: {.cv-keys}               bullet list of `- key | value` items,
--                                bold col 1, default row gap 2.5pt
--   ::: {.cv-publications}       ordered list, hanging-indent enumerate
--                                matching enumitem options of the original CV
--   ::: {.cv-references}         wraps nested .referee subdivs in a
--                                two-column multicols block separated by
--                                \vfill\columnbreak
--
-- Recognized inline span:
--
--   [text]{.role}                \textbf{\small text}, for the "as Lecturer"
--                                qualifier beside a bold heading
--
-- Attributes on .cv-entries and .cv-keys:
--
--   gap="2.5pt"                  row separator length; gap="" gives a bare \\
--   trailing="true"              also emit the separator after the final row.
--                                That adds an empty last row, which lengthens
--                                the \VRule slightly and leaves a little space
--                                below the block. Off by default; rows are
--                                normally separated only between entries.
--
-- Skipped silently when the output is not LaTeX (HTML preview, etc.).

if FORMAT ~= "latex" then return {} end

-- These handlers degrade to plain pandoc rendering rather than erroring, so a
-- malformed div silently loses its layout. Say so on stderr.
local function warn(msg)
  if quarto and quarto.log and quarto.log.warning then
    quarto.log.warning(msg)
  else
    io.stderr:write("[qkit-cv] " .. msg .. "\n")
  end
end

local function tex(inlines, in_cell)
  -- Convert a list of Pandoc inlines to LaTeX via the writer. Strip trailing
  -- whitespace so we can compose into a row cell cleanly.
  --
  -- in_cell rewrites hard line breaks to \newline. Inside a tabular the
  -- writer's default \\ would end the row mid-cell, which fails the build
  -- with "Missing } inserted". Authors can then write either an explicit
  -- \newline or a markdown trailing backslash.
  local doc = pandoc.Pandoc({pandoc.Plain(inlines)})
  if in_cell then
    doc = doc:walk({
      LineBreak = function() return pandoc.RawInline("latex", " \\newline ") end,
    })
  end
  return (pandoc.write(doc, "latex"):gsub("%s+$", ""))
end

local function is_strong_only(inlines)
  return #inlines == 1 and inlines[1].t == "Strong"
end

local function find_first(blocks, tag)
  for _, b in ipairs(blocks) do
    if b.t == tag then return b end
  end
  return nil
end

-- Split a flat list of inlines at the first `|` token. Returns two
-- inline lists (key, value) with surrounding whitespace trimmed, or nil if
-- no separator is present.
local function split_at_pipe(inlines)
  local key, val, found = pandoc.List({}), pandoc.List({}), false
  for _, inl in ipairs(inlines) do
    if not found and inl.t == "Str" and inl.text == "|" then
      found = true
    elseif not found then
      key:insert(inl)
    else
      val:insert(inl)
    end
  end
  if not found then return nil end
  while #key > 0 and key[#key].t == "Space" do key:remove(#key) end
  while #val > 0 and val[1].t == "Space" do val:remove(1) end
  return key, val
end

local function handle_table_div(div, key_style, default_gap)
  local list = find_first(div.content, "BulletList")
  if not list or #list.content == 0 then
    warn("cv-entries/cv-keys: no bullet list found; div left as plain "
      .. "markdown, losing the date column and vertical rule. Entries "
      .. "must be written as `- key | value`.")
    return nil
  end
  local gap = div.attributes.gap or default_gap
  -- gap="" gives a bare \\ with no bracketed length.
  local rowsep = (gap == "") and "\\\\" or string.format("\\\\[%s]", gap)
  -- trailing="true" also emits the separator after the final row. That adds
  -- an empty last row, which lengthens the \VRule slightly and leaves a gap
  -- below the block.
  local trailing = div.attributes.trailing == "true"

  local out = {[[\begin{tabular}{L!{\VRule width 1pt}R}]]}
  local n = #list.content
  for i, item in ipairs(list.content) do
    local item_inlines = pandoc.utils.blocks_to_inlines(item)
    local key_inlines, val_inlines = split_at_pipe(item_inlines)
    if not key_inlines then
      warn("cv-entries/cv-keys: skipping an item with no `|` separator: "
        .. pandoc.utils.stringify(item_inlines))
    end
    if key_inlines then
      local key_tex
      if is_strong_only(key_inlines) then
        key_tex = tex(key_inlines, true)
      elseif key_style == "italic" then
        key_tex = string.format("\\textit{%s}", tex(key_inlines, true))
      else
        key_tex = string.format("\\textbf{%s}", tex(key_inlines, true))
      end
      local sep = (i < n or trailing) and rowsep or ""
      table.insert(out, string.format("%s&{%s}%s", key_tex, tex(val_inlines, true), sep))
    end
  end
  table.insert(out, [[\end{tabular}]])
  return pandoc.RawBlock("latex", table.concat(out, "\n"))
end

local function handle_publications(div)
  local olist = find_first(div.content, "OrderedList")
  if not olist then
    warn("cv-publications: no ordered list found; div left as plain markdown, "
      .. "losing the hanging-indent enumerate.")
    return nil
  end
  local out = {
    [==[\begin{enumerate}[labelindent=0pt,labelwidth=\widthof{\ref{last-item}},label=\arabic*.,itemindent=0em,leftmargin=2.75em]]==]
  }
  for _, item in ipairs(olist.content) do
    table.insert(out, "\\item " .. tex(pandoc.utils.blocks_to_inlines(item)))
  end
  table.insert(out, [[\end{enumerate}]])
  return pandoc.RawBlock("latex", table.concat(out, "\n"))
end

-- Referees are grouped `cols` at a time, each group in its own multicols.
-- One multicols holding every referee does not give a grid: with N > cols
-- entries the extras flow past the column set and land on the next page.
local function handle_references(div)
  local cols = tonumber(div.attributes.cols or "2") or 2
  local entries = {}
  for _, b in ipairs(div.content) do
    if b.t == "Div" and b.classes:includes("referee") then
      local inner = pandoc.Pandoc(b.content)
      table.insert(entries, (pandoc.write(inner, "latex"):gsub("%s+$", "")))
    end
  end
  if #entries == 0 then
    warn("cv-references: no nested .referee divs found; div left as plain "
      .. "markdown, losing the two-column layout.")
    return nil
  end

  local out = {}
  for i = 1, #entries, cols do
    local group = {}
    for j = i, math.min(i + cols - 1, #entries) do
      table.insert(group, entries[j])
    end
    -- A short final group (odd count) would otherwise be balanced across
    -- every column, splitting one referee down the middle.
    local pad = ""
    for _ = #group + 1, cols do
      pad = pad .. "\n\n\\vfill\\columnbreak\n\n\\mbox{}"
    end
    table.insert(out, pandoc.RawBlock("latex",
      string.format("\\begin{multicols}{%d}\n%s%s\n\\end{multicols}",
        cols, table.concat(group, "\n\n\\vfill\\columnbreak\n\n"), pad)))
  end
  return out
end

-- [text]{.role} -> \textbf{\small text}
--
-- The "as Lecturer" / "at Some University" qualifier that sits beside a bold
-- heading in the experience lists, so the source stays markdown.
function Span(sp)
  if sp.classes:includes("role") then
    return pandoc.RawInline("latex",
      string.format("\\textbf{\\small %s}", tex(sp.content)))
  end
  -- [text]{.note}: the indented, asterisk-marked aside under a list, as in
  -- "*Presentations by co-authors". The asterisk stays upright.
  if sp.classes:includes("note") then
    return pandoc.RawInline("latex",
      string.format("\\hspace{1em} *\\textit{%s}", tex(sp.content)))
  end
  return nil
end

-- [addr](mailto:addr){.mail} -> envelope then the link.
--
-- The forced space after \Letter is required: it is a control word, so TeX
-- would swallow a plain space and butt the icon against the address. Emitting
-- the \href directly also avoids pandoc's \nolinkurl, which it applies when a
-- link's text equals its target and which styles the text as a URL.
function Link(l)
  if not l.classes:includes("mail") then return nil end
  if (l.target or ""):sub(1, 7) ~= "mailto:" then return nil end
  return pandoc.RawInline("latex",
    string.format("\\Letter\\ \\href{%s}{%s}", l.target, tex(l.content)))
end

function Div(div)
  if div.classes:includes("cv-entries") then
    return handle_table_div(div, "italic", "15pt")
  elseif div.classes:includes("cv-keys") then
    return handle_table_div(div, "bold", "2.5pt")
  elseif div.classes:includes("cv-publications") then
    return handle_publications(div)
  elseif div.classes:includes("cv-references") then
    return handle_references(div)
  end
end

-- Auto-inject the horizontal rule under each top-level section heading so
-- the user doesn't have to write the boilerplate after every # in the source.
-- We emit \vspace{-15pt}, \noindent, and \rule{\textwidth}{1pt} as three
-- separate RawBlocks; the blank lines Pandoc inserts between them produce
-- the small \parskip-driven vertical breathing room between the heading
-- and the rule that the hand-written skeleton had.
function Header(h)
  if h.level == 1 then
    return {
      h,
      pandoc.RawBlock("latex", "\\vspace{-15pt}"),
      pandoc.RawBlock("latex", "\\noindent"),
      pandoc.RawBlock("latex", "\\rule{\\textwidth}{1pt}")
    }
  end
end
