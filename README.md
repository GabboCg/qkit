# qkit <img src="man/figures/logo.png" align="right" height="138" />

**Author:** [Gabriel Cabrera](https://github.com/gabbocg)<br>
**License:** [MIT](https://opensource.org/licenses/MIT) + file [LICENSE](LICENSE)

<!-- badges: start -->
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

## Overview

**qkit** is a set of personal [Quarto](https://quarto.org) templates with RStudio integration. It ships five template types — a Beamer presentation, an academic CV, a Quarto book project, a minimalist academic paper, and a course syllabus — each with a sensible LaTeX preamble, ORCID-aware author handling, and a one-click *File > New Project* entry in RStudio.

Inspired by [beamer-tips](https://github.com/paulgp/beamer-tips), adapted for a Quarto-based workflow and extended with four more formats.

## Installation

```r
# install.packages("remotes")
remotes::install_github("gabbocg/qkit")
```

You also need [Quarto](https://quarto.org/docs/get-started/) and a
working TeX distribution (TinyTeX or TeX Live). After installing
`qkit`, restart RStudio once so the wizard picks up the new project
templates.

## Templates

| Type | RStudio wizard entry | Output | Files dropped |
|------|----------------------|--------|---------------|
| `beamer` | qkit Beamer Presentation | XeLaTeX slides | `index.qmd` + `_extensions/qkit/` |
| `cv` | qkit CV | LuaLaTeX one-pager | `index.qmd` + `_extensions/qkit/` |
| `book` | qkit Book | XeLaTeX book (Krantz class) | full multi-file Quarto book project |
| `paper` | qkit Paper | XeLaTeX article + Internet Appendix | `index.qmd`, `internet-appendix.qmd`, `title.tex`, `preamble.tex`, `preamble-appendix.tex`, `mark-last-author.lua`, `eq-parens.lua`, `float-notes.lua`, `example-figure.pdf`, `references.bib`, `references-appendix.bib` |
| `syllabus` | qkit Syllabus | pdfLaTeX article (Palatino) | `index.qmd`, `preamble.tex`, `before-body.tex`, `references.bib`, `logo.pdf` |

The Beamer and CV formats are backed by a Quarto extension; Book,
Paper and Syllabus are self-contained project scaffolds (no extension
installed).

## Usage

### From RStudio

*File > New Project > New Directory*, pick one of the five `qkit`
entries, fill in the wizard fields, and click *Create*. RStudio
opens the scaffolded `index.qmd` in the editor.

### From the R console

```r
qkit::create_project("my-slides", type = "beamer", title = "Talk Title")
qkit::create_project("my-cv",     type = "cv",     author = "Your Name")
qkit::create_project("my-book",   type = "book",   title = "Book Title", author = "Your Name")
qkit::create_project("my-paper",  type = "paper",  title = "Paper Title")
qkit::create_project("my-course", type = "syllabus", title = "Course Title", author = "Your Name")
```

To render an already-scaffolded document:

```r
qkit::qkit_render("my-slides/index.qmd")
qkit::qkit_preview("my-slides/index.qmd")   # live-reload preview
```

`qkit_render()` auto-installs the qkit Quarto extension into the
project directory if it isn't already there (only relevant for
`beamer` and `cv` — the book, paper and syllabus formats don't use
the extension).

To install the qkit Quarto extension manually into any existing
Quarto project:

```r
qkit::install_extension(path = ".")
```

### YAML format keys

| Format | YAML `format:` entry |
|--------|----------------------|
| Beamer | `qkit-beamer` |
| CV     | `qkit-pdf` |
| Book   | configured in `_quarto.yml`'s `format: pdf:` block (no extension key) |
| Paper  | configured in `index.qmd`'s `format: pdf:` block (no extension key) |
| Syllabus | configured in `index.qmd`'s `format: pdf:` block (no extension key) |

## Per-template features

### Beamer (`qkit-beamer`)

- Custom color palette (blue, red, yellow, green)
- Bullet styling, itemize / enumerate spacing
- Custom footline with frame numbers and navigation buttons
- Yellow section-break slides
- Multiple authors with affiliations and ORCID
- Short title and short author support
- Callout styling (note, warning)
- Text justification across frames

### CV (`qkit-pdf`)

- LuaLaTeX engine with `mathpazo` font
- A small Pandoc Lua filter lets you write the CV in mostly-pure
  markdown via four semantic divs: `.cv-entries` (italic-key two-col
  table), `.cv-keys` (bold-key two-col table), `.cv-publications`
  (hanging-indent numbered list), `.cv-references` (two-column
  multicols block of `.referee` subdivs)
- Automatic horizontal rule under every `# Section` heading
- Fontawesome contact icons in the title header (email, phone,
  GitHub, web)
- Optional ORCID link via `orcidlink`
- Right-aligned "Updated: \today" stamp at the end of the document,
  controlled by `updated: true` in YAML
- Page footer with author / title on the centre and `page / total`
  on the right

### Book (qkit Book)

- Multi-file Quarto book project (`_quarto.yml` with `project: type:
  book`)
- Krantz document class (`krantz.cls` shipped in the scaffold)
- xelatex engine, `makeindex`, `sourcecodepro` font for code
- Generic title-page partial with optional ORCID and affiliation;
  no PhD-thesis specifics
- Optional dedication page (uncomment a block in `index.qmd` to
  enable; renders for both PDF and HTML)
- Book-friendly date format (`MMMM YYYY` → "May 2026")
- Sample chapter scaffold: preface, intro, one part with two
  chapters, references, one appendix

### Paper (qkit Paper)

- Minimalist 12pt `article`, 1in margins, doublespaced body,
  one-and-a-half-spaced title block and tables
- Structured-YAML author list with ORCID, email, affiliations,
  and an optional `corresponding: true` flag — rendered by a
  custom `title.tex` Pandoc partial as
  `Name\textsuperscript{\orcidlink{...}}\thanks{Email: \href{mailto:...}{...}. Address: ...}`
  for each author
- Oxford-comma joining of the author list (`A`, `A and B`, or
  `A, B, and C`) driven by a Pandoc Lua filter
  (`mark-last-author.lua`) that annotates the YAML list with
  `is-first` / `is-last` / `next-is-last` flags
- Italic subsection headings, period-after-section numbering
  (`1. Introduction`), 1.5cm-indented quote env, symmetric
  display-equation spacing pinned to 12pt on all four
  `\abovedisplayskip` / `\belowdisplayskip` / `*shortskip`
  lengths
- "Preliminary draft --- please do not cite without permission"
  italic subtitle on the same line as the title; the title's
  `\thanks{}` acknowledgment footnote sits next to the title
  text, not the subtitle
- JEL Classification line below the abstract's Keywords
- Footnotes pinned to the bottom of every page via
  `\usepackage[bottom]{footmisc}`
- In-paper Appendix block (`\appendix` + `\thesection = Appendix
  A`)
- Separate `internet-appendix.qmd` with a custom `\maketitle`
  redefinition (in `preamble-appendix.tex`) emitting the
  "Internet Appendix for / Title / Authors / SUPPLEMENTARY
  RESULTS" centered title page, plus its own
  `references-appendix.bib`
- LaTeX preamble externalised into `preamble.tex` and
  `preamble-appendix.tex` so it can be edited without touching
  the YAML header
- References on a new page after the Conclusion (and at the end
  of the Internet Appendix)
- natbib/BibTeX for bibliographies (`apalike`, with
  `\setcitestyle{aysep={}}` giving Chicago-style author-date), so
  both halves of a citation are hyperlinked
- Body is a self-documenting Quarto tutorial: each section walks
  through a Quarto/Markdown feature (cross-reference prefixes,
  labeled equations, theorem environments, citation styles,
  callouts, knitr table chunks, pipe tables, definition lists,
  raw `{=tex}`/`{=html}` blocks, `.content-visible
  when-format=...` conditional content)

### Syllabus (qkit Syllabus)

- 11pt `article`, 1in margins, Palatino (`mathpazo`), unnumbered
  sections — ported from the R Markdown syllabus template in
  [py4Fin](https://github.com/gabbocg/py4Fin)
- Course-information block driven entirely from YAML: `email:`,
  `web:`, `officehours:`, `classhours:`, `office:`, `classroom:`,
  each falling back to *TBD* when omitted, rendered as a full-width
  two-column rule-terminated table under the title
- `term:` instead of `date:` for the academic term, so "Fall 2026"
  survives Quarto's date normalisation
- Running head carrying the course title and term, and a
  `page / total` footer via `lastpage`; page 1 takes the page number
  but neither rule nor running head
- Institution logo above the title (`logo:`, `logo-width:`), on by
  default via a self-labelling `logo.pdf` placeholder — swap the file,
  keep the name
- natbib/BibTeX reading list generated from every entry in
  `references.bib` via `nocite: "@*"`, headed by `\refname`; all five
  shipped entries are invented placeholders
- pdfLaTeX with the typewriter and sans families forced to Latin
  Modern, so code spans embed as Type 1 rather than Type 3 bitmaps
- Body is a self-documenting English syllabus: description,
  objectives, prerequisites and materials, methodology, grading, a
  dated week-by-week schedule table, a nested course outline, and
  policy subsections (academic integrity, late work, attendance,
  accessibility)

## Getting help

If you encounter a bug, please file an issue with a minimal reproducible example on [GitHub](https://github.com/gabbocg/qkit/issues). For questions, email gabriel.cabreraguzman@postgrad.manchester.ac.uk.
