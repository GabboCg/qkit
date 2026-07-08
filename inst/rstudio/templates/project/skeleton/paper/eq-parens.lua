--[[
  eq-parens.lua
  -------------
  Render equation cross-references (@eq-*) as "Eq. (N)" — with the
  reference number wrapped in parentheses — via amsmath's \eqref.

  For LaTeX/PDF output, any Cite element whose target is an
  equation label (e.g. `@eq-baseline`) is replaced by a raw
  LaTeX inline of the form  Eq.~\eqref{eq-baseline}, which
  hyperref renders as "Eq. (N)" in linkcolor.

  Non-equation cross-references (sections, tables, figures) are
  left alone so Quarto's own crossref processing keeps working.

  LaTeX/PDF/Beamer only; other formats pass through unchanged.
--]]

local function is_latex()
  return FORMAT == "latex" or FORMAT == "pdf" or FORMAT == "beamer"
end

--- Intercept a Cite element whose (sole) citation is an equation
--- label and emit a raw-LaTeX \eqref{} call.
function Cite(el)
  if not is_latex() then return nil end
  if not el.citations or #el.citations == 0 then return nil end

  -- Only rewrite when EVERY citation in the Cite targets an
  -- equation label — otherwise leave the node alone so mixed
  -- citations behave sensibly.
  local eq_ids = {}
  for _, cite in ipairs(el.citations) do
    local id = cite.id
    if not id:match("^eq%-") then return nil end
    eq_ids[#eq_ids + 1] = id
  end

  if #eq_ids == 1 then
    return pandoc.RawInline("latex",
      "Eq.~\\eqref{" .. eq_ids[1] .. "}")
  end

  -- Multiple equation citations grouped together, e.g.
  --   see [@eq-a; @eq-b]
  -- render as "Eqs. (1) and (2)".
  local parts = {}
  for i, id in ipairs(eq_ids) do
    parts[i] = "\\eqref{" .. id .. "}"
  end
  local joined
  if #eq_ids == 2 then
    joined = parts[1] .. " and " .. parts[2]
  else
    joined = table.concat(parts, ", ", 1, #parts - 1)
             .. ", and " .. parts[#parts]
  end
  return pandoc.RawInline("latex", "Eqs.~" .. joined)
end
