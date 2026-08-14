# Tests for the syllabus skeleton. The failure modes guarded here are all
# silent -- none of them stops a render, so nothing but an assertion or a
# careful reading of the PDF catches them:
#
#   * dropping before-body.tex from `template-partials` falls back to
#     Quarto's stock partial, which quietly loses the whole
#     course-information table AND the \date{} that carries `term:`;
#   * writing `date:` instead of `term:` renders "Fall 2026" as
#     2026-01-01, because Quarto normalises anything it can parse;
#   * leaving \ttdefault alone lets mathpazo's Computer Modern typewriter
#     resolve to METAFONT ec fonts, which pdflatex embeds as Type 3
#     bitmaps;
#   * an at-sign inside a %-comment in the .bib starts a bogus BibTeX
#     entry, since BibTeX has no comment syntax.

syllabus_dir <- function() {
  src <- "../../inst/rstudio/templates/project/skeleton/syllabus"
  if (dir.exists(src)) return(src)
  installed <- system.file(
    "rstudio/templates/project/skeleton/syllabus", package = "qkit"
  )
  testthat::skip_if(identical(installed, ""), "syllabus skeleton not found")
  installed
}

test_that("syllabus skeleton ships its five files", {
  d <- syllabus_dir()
  for (f in c("index.qmd", "preamble.tex", "before-body.tex", "references.bib",
              "logo.pdf")) {
    expect_true(file.exists(file.path(d, f)), info = paste(f, "is missing"))
  }
})

test_that("the placeholder logo is shipped AND switched on", {
  # These two have to move together. `logo:` pointing at a file that is not
  # in the skeleton is a hard render error, and shipping the image while
  # leaving the key commented means nobody discovers the feature.
  d <- syllabus_dir()
  expect_true(file.exists(file.path(d, "logo.pdf")))
  lines <- readLines(file.path(d, "index.qmd"), warn = FALSE)
  expect_true(any(grepl("^logo: logo.pdf", lines)))

  # titling is what lets the logo share page 1 with the title: article's
  # own \@maketitle opens with \newpage, so a logo emitted before it would
  # be stranded on a page of its own.
  tex <- readLines(file.path(d, "preamble.tex"), warn = FALSE)
  expect_true(any(grepl("\\usepackage{titling}", tex, fixed = TRUE)))
  partial <- readLines(file.path(d, "before-body.tex"), warn = FALSE)
  expect_true(any(grepl("\\pretitle{", partial, fixed = TRUE)))
})

test_that("index.qmd registers before-body.tex as a template partial", {
  d <- syllabus_dir()
  lines <- readLines(file.path(d, "index.qmd"), warn = FALSE)
  expect_true(any(grepl("template-partials", lines, fixed = TRUE)))
  expect_true(any(grepl("- before-body.tex", lines, fixed = TRUE)))
  expect_true(any(grepl("include-in-header: preamble.tex", lines, fixed = TRUE)))
})

test_that("the course term uses term:, not Quarto's date:", {
  d <- syllabus_dir()
  lines <- readLines(file.path(d, "index.qmd"), warn = FALSE)
  expect_true(any(grepl("^term:", lines)))
  expect_false(any(grepl("^date:", lines)))

  partial <- readLines(file.path(d, "before-body.tex"), warn = FALSE)
  expect_true(any(grepl("\\date{$term$}", partial, fixed = TRUE)))
})

test_that("the course information table wraps rather than overflowing", {
  # The py4Fin original used tabular* with l/r columns, which are set at
  # their natural width and cannot wrap: the stock office-hours and
  # class-hours strings together ran 54.8pt past the right margin. The
  # only symptom was an Overfull \hbox in the log -- pdftotext shows the
  # words happily, so no text-based check catches it.
  d <- syllabus_dir()
  partial <- readLines(file.path(d, "before-body.tex"), warn = FALSE)
  expect_true(any(grepl("\\begin{tabularx}", partial, fixed = TRUE)))
  expect_false(any(grepl("\\begin{tabular*}", partial, fixed = TRUE)))
  expect_true(any(grepl("\\raggedright\\arraybackslash", partial, fixed = TRUE)))
  expect_true(any(grepl("\\raggedleft\\arraybackslash", partial, fixed = TRUE)))

  tex <- readLines(file.path(d, "preamble.tex"), warn = FALSE)
  expect_true(any(grepl("\\usepackage{tabularx}", tex, fixed = TRUE)))
})

test_that("before-body.tex builds the six-field course information table", {
  d <- syllabus_dir()
  partial <- readLines(file.path(d, "before-body.tex"), warn = FALSE)
  for (field in c("email", "web", "officehours", "classhours",
                  "office", "classroom")) {
    expect_true(
      any(grepl(paste0("$if(", field, ")$"), partial, fixed = TRUE)),
      info = paste("before-body.tex does not read", field)
    )
  }
  # Every field falls back to TBD, so an unscheduled course still gets a
  # table of the right shape rather than blank cells.
  expect_equal(sum(vapply(partial, function(l) {
    lengths(regmatches(l, gregexpr("$else$TBD$endif$", l, fixed = TRUE)))
  }, integer(1))), 6L)
})

test_that("preamble.tex wires the running head and the page x/y footer", {
  d <- syllabus_dir()
  tex <- readLines(file.path(d, "preamble.tex"), warn = FALSE)
  expect_true(any(grepl("\\usepackage{lastpage}", tex, fixed = TRUE)))
  expect_true(any(grepl("\\pageref*{LastPage}", tex, fixed = TRUE)))
  expect_true(any(grepl("\\fancypagestyle{firststyle}", tex, fixed = TRUE)))
  # firststyle is only ever reached via before-body.tex.
  partial <- readLines(file.path(d, "before-body.tex"), warn = FALSE)
  expect_true(any(grepl("\\thispagestyle{firststyle}", partial, fixed = TRUE)))
})

test_that("preamble.tex keeps the typewriter family off METAFONT", {
  d <- syllabus_dir()
  tex <- readLines(file.path(d, "preamble.tex"), warn = FALSE)
  expect_true(any(grepl("\\renewcommand{\\ttdefault}{lmtt}", tex, fixed = TRUE)))
})

test_that("the reading-list heading comes from refname, not citeproc", {
  d <- syllabus_dir()
  tex <- readLines(file.path(d, "preamble.tex"), warn = FALSE)
  expect_true(any(grepl("\\renewcommand{\\refname}", tex, fixed = TRUE)))

  lines <- readLines(file.path(d, "index.qmd"), warn = FALSE)
  expect_true(any(grepl("cite-method: natbib", lines, fixed = TRUE)))
  # apalike ships in TeX Live base, so it resolves under TinyTeX too.
  expect_true(any(grepl("biblio-style: apalike", lines, fixed = TRUE)))
})

test_that("references.bib carries no at-sign outside an entry", {
  d <- syllabus_dir()
  bib <- readLines(file.path(d, "references.bib"), warn = FALSE)
  comments <- grep("^\\s*%", bib, value = TRUE)
  expect_false(
    any(grepl("@", comments, fixed = TRUE)),
    info = "an at-sign in a .bib comment starts a bogus BibTeX entry"
  )
})

test_that("the schedule table is not prefixed with a literal Table", {
  # Quarto supplies the "Table" prefix itself, so `Table @tbl-x` renders
  # as "Table Table 1". The one permitted hit is the sentence in the
  # template that explains that trap, and it is inside backticks.
  d <- syllabus_dir()
  lines <- readLines(file.path(d, "index.qmd"), warn = FALSE)
  offenders <- grep("[^`]Table @tbl-", lines, value = TRUE)
  expect_length(offenders, 0L)
})

test_that("create_project() scaffolds a syllabus with substitutions", {
  skip_if_not_installed("fs")
  dir <- file.path(tempdir(), "qkit-syllabus-test")
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  unlink(dir, recursive = TRUE)

  create_project(dir, type = "syllabus",
                 title = "Python for Finance", author = "Ada Lovelace")

  expect_true(file.exists(file.path(dir, "index.qmd")))
  expect_true(file.exists(file.path(dir, "preamble.tex")))
  expect_true(file.exists(file.path(dir, "before-body.tex")))
  expect_true(file.exists(file.path(dir, "references.bib")))
  # The syllabus is self-contained, like book and paper: no extension.
  expect_false(dir.exists(file.path(dir, "_extensions")))

  lines <- readLines(file.path(dir, "index.qmd"), warn = FALSE)
  # The course-code prefix survives; only the trailing half is replaced.
  expect_true(any(grepl('title: "ECON 000 --- Python for Finance"',
                        lines, fixed = TRUE)))
  expect_true(any(grepl('author: "Ada Lovelace"', lines, fixed = TRUE)))
  expect_false(any(grepl("Your Course Title", lines, fixed = TRUE)))
  expect_false(any(grepl("Your Name", lines, fixed = TRUE)))
})
