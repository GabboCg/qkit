# Tests for the qkit-syllabus extension -- the format contract plus the two
# .tex files it carries. Every failure mode guarded here is silent in the
# render: the syllabus still builds, it just comes out wrong.

syllabus_ext <- function() {
  src <- "../../inst/extdata/_extensions/qkit-syllabus"
  if (dir.exists(src)) return(src)
  installed <- system.file(
    "extdata/_extensions/qkit-syllabus", package = "qkit"
  )
  testthat::skip_if(identical(installed, ""), "qkit-syllabus extension not found")
  installed
}

ext_yml <- function() readLines(file.path(syllabus_ext(), "_extension.yml"), warn = FALSE)
ext_partial <- function() readLines(file.path(syllabus_ext(), "before-body.tex"), warn = FALSE)
ext_preamble <- function() readLines(file.path(syllabus_ext(), "preamble.tex"), warn = FALSE)

test_that("the extension ships its three files", {
  d <- syllabus_ext()
  for (f in c("_extension.yml", "before-body.tex", "preamble.tex")) {
    expect_true(file.exists(file.path(d, f)), info = paste(f, "is missing"))
  }
})

test_that("the extension contributes a pdf format", {
  # The directory name is what users write, so this resolves to
  # `format: qkit-syllabus-pdf`. It is a separate directory from
  # _extensions/qkit precisely because that one already claims `pdf` for the
  # CV and Quarto allows one format per base format per directory.
  yml <- ext_yml()
  expect_true(any(grepl("^contributes:", yml)))
  expect_true(any(grepl("^\\s+formats:", yml)))
  expect_true(any(grepl("^\\s+pdf:", yml)))
})

test_that("the format registers both .tex files", {
  # Dropping before-body.tex falls back to Quarto's stock partial, which
  # quietly loses the whole course-information table AND the \date{} that
  # carries `term:`.
  yml <- ext_yml()
  expect_true(any(grepl("template-partials", yml, fixed = TRUE)))
  expect_true(any(grepl("- before-body.tex", yml, fixed = TRUE)))
  expect_true(any(grepl("include-in-header: preamble.tex", yml, fixed = TRUE)))
})

test_that("the format pins pdflatex together with mathpazo", {
  # Pandoc only honours `fontfamily:` on the pdftex path. Under xelatex or
  # lualatex it loads fontspec and ignores the key, so the syllabus would
  # silently render in Latin Modern instead of Palatino.
  yml <- ext_yml()
  expect_true(any(grepl("pdf-engine: pdflatex", yml, fixed = TRUE)))
  expect_true(any(grepl("fontfamily: mathpazo", yml, fixed = TRUE)))
})

test_that("the citation settings travel with the preamble that needs them", {
  # preamble.tex sets \refname and \setcitestyle, which only take effect on
  # the natbib path. Split these across the extension and the document and a
  # syllabus that omits them silently falls back to citeproc, losing the
  # "Recommended Readings" heading.
  yml <- ext_yml()
  expect_true(any(grepl("cite-method: natbib", yml, fixed = TRUE)))
  expect_true(any(grepl("biblio-style: apalike", yml, fixed = TRUE)))

  tex <- ext_preamble()
  expect_true(any(grepl("\\renewcommand{\\refname}", tex, fixed = TRUE)))
})

test_that("before-body.tex builds the six-field course information table", {
  partial <- ext_partial()
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

test_that("the course information table wraps rather than overflowing", {
  # tabular* with l/r columns is set at its natural width and cannot wrap:
  # the stock office-hours and class-hours strings together ran 54.8pt past
  # the right margin, and the only symptom was an Overfull \hbox in the log.
  partial <- ext_partial()
  expect_true(any(grepl("\\begin{tabularx}", partial, fixed = TRUE)))
  expect_false(any(grepl("\\begin{tabular*}", partial, fixed = TRUE)))
  expect_true(any(grepl("\\raggedright\\arraybackslash", partial, fixed = TRUE)))
  expect_true(any(grepl("\\raggedleft\\arraybackslash", partial, fixed = TRUE)))
  expect_true(any(grepl("\\usepackage{tabularx}", ext_preamble(), fixed = TRUE)))
})

test_that("before-body.tex hangs the logo off titling's pretitle", {
  # titling is what lets the logo share page 1 with the title: article's own
  # \@maketitle opens with \newpage, so a logo emitted before it would be
  # stranded on a page of its own.
  expect_true(any(grepl("\\pretitle{", ext_partial(), fixed = TRUE)))
  expect_true(any(grepl("\\usepackage{titling}", ext_preamble(), fixed = TRUE)))
})

test_that("before-body.tex routes term: into date:", {
  # Quarto normalises anything it can parse as a date, so "Fall 2026" written
  # as `date:` comes back out as 2026-01-01.
  expect_true(any(grepl("\\date{$term$}", ext_partial(), fixed = TRUE)))
})

test_that("preamble.tex wires the running head and the page x/y footer", {
  tex <- ext_preamble()
  expect_true(any(grepl("\\usepackage{lastpage}", tex, fixed = TRUE)))
  expect_true(any(grepl("\\pageref*{LastPage}", tex, fixed = TRUE)))
  expect_true(any(grepl("\\fancypagestyle{firststyle}", tex, fixed = TRUE)))
  # firststyle is only ever reached via before-body.tex.
  expect_true(any(grepl("\\thispagestyle{firststyle}", ext_partial(), fixed = TRUE)))
})

test_that("preamble.tex keeps the typewriter family off METAFONT", {
  # Under T1, mathpazo leaves tt at Computer Modern, which resolves to the
  # METAFONT ec fonts -- pdflatex then embeds them as Type 3 bitmaps and every
  # code span renders fuzzy and unsearchable.
  expect_true(any(grepl("\\renewcommand{\\ttdefault}{lmtt}", ext_preamble(), fixed = TRUE)))
})

test_that("the shipped copy matches the development copy", {
  # _extensions/ is what renders inside this repo; inst/extdata/_extensions is
  # what install_extension() copies out. They drift silently.
  dev <- "../../_extensions/qkit-syllabus"
  ship <- "../../inst/extdata/_extensions/qkit-syllabus"
  testthat::skip_if_not(dir.exists(dev) && dir.exists(ship),
                        "running against an installed package")
  for (f in c("_extension.yml", "before-body.tex", "preamble.tex")) {
    expect_identical(
      readLines(file.path(dev, f), warn = FALSE),
      readLines(file.path(ship, f), warn = FALSE),
      info = paste(f, "differs between _extensions/ and inst/extdata/")
    )
  }
})
