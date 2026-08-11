-- Attach a note to a float's caption.
--
-- Gives markdown figures and tables a `note=` attribute:
--
--   ![Title](fig.pdf){#fig-x note="This figure displays ..."}
--
-- Quarto wraps every cross-referenceable float in a FloatRefTarget
-- custom AST node exposing `type`, `identifier`, `attributes`, and a
-- mutable `caption_long`. The note is parsed as markdown and appended to
-- the caption as \floatnote{...} (defined in preamble.tex).
--
-- Appending rather than splicing raw LaTeX keeps the note in the AST, so
-- Quarto's own citeproc/natbib and crossref filters process @citekey and
-- @eq-x inside a note exactly as they do in body text.
--
-- A float only becomes a FloatRefTarget when it carries a #fig- or #tbl-
-- identifier, so `note=` on an unlabelled float is silently dropped.
-- That limitation is documented in the template prose.

local function note_inlines(str)
  local parsed = pandoc.read(str, "markdown").blocks
  local out = pandoc.Inlines({pandoc.RawInline("latex", "\\floatnote{")})
  for i, blk in ipairs(parsed) do
    if blk.content then
      if i > 1 then out:insert(pandoc.Space()) end
      out:extend(blk.content)
    end
  end
  out:insert(pandoc.RawInline("latex", "}"))
  return out
end

return {
  {
    FloatRefTarget = function(float)
      local note = float.attributes and float.attributes.note
      if not note then return nil end
      float.attributes.note = nil

      local caption = float.caption_long
      if caption == nil then return nil end

      -- caption_long is a single Block for the floats Quarto generates;
      -- the else branch handles a Blocks list in case that changes.
      if caption.content ~= nil then
        caption.content:extend(note_inlines(note))
      else
        local last = caption[#caption]
        if last and last.content then
          last.content:extend(note_inlines(note))
        end
      end

      float.caption_long = caption
      return float
    end
  }
}
