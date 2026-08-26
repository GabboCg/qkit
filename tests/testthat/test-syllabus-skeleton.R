# Tests for the syllabus skeleton -- the document the user actually edits.
# The styling it relies on lives in the qkit-syllabus extension and is
# covered by test-syllabus-extension.R.
#
# The failure modes guarded here are all silent -- none of them stops a
# render, so nothing but an assertion or a careful reading of the PDF
# catches them:
#
#   * writing `date:` instead of `term:` renders "Fall 2026" as
#     2026-01-01, because Quarto normalises anything it can parse;
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

skeleton_qmd <- function() readLines(file.path(syllabus_dir(), "index.qmd"), warn = FALSE)

test_that("syllabus skeleton ships its three files", {
  # The two .tex files used to live here; they moved into the extension when
  # the syllabus stopped being a self-contained scaffold.
  d <- syllabus_dir()
  for (f in c("index.qmd", "references.bib", "logo.pdf")) {
    expect_true(file.exists(file.path(d, f)), info = paste(f, "is missing"))
  }
  for (f in c("preamble.tex", "before-body.tex")) {
    expect_false(file.exists(file.path(d, f)),
                 info = paste(f, "should live in the extension, not the skeleton"))
  }
})

test_that("index.qmd selects the qkit-syllabus format", {
  # Without this the document renders as a plain Quarto PDF: no logo, no
  # course-information table, no running head, no natbib reading list.
  expect_true(any(grepl("qkit-syllabus-pdf", skeleton_qmd(), fixed = TRUE)))
})

test_that("the placeholder logo is shipped AND switched on", {
  # These two have to move together. `logo:` pointing at a file that is not
  # in the skeleton is a hard render error, and shipping the image while
  # leaving the key commented means nobody discovers the feature.
  expect_true(file.exists(file.path(syllabus_dir(), "logo.pdf")))
  expect_true(any(grepl("^logo: logo.pdf", skeleton_qmd())))
})

test_that("the course term uses term:, not Quarto's date:", {
  lines <- skeleton_qmd()
  expect_true(any(grepl("^term:", lines)))
  expect_false(any(grepl("^date:", lines)))
})

test_that("the skeleton fills in every course-information field", {
  # Each one omitted renders as TBD, which is the right fallback for a real
  # course but would make the shipped template look half-finished.
  lines <- skeleton_qmd()
  for (field in c("email", "web", "officehours", "classhours",
                  "office", "classroom")) {
    expect_true(any(grepl(paste0("^", field, ":"), lines)),
                info = paste("skeleton does not set", field))
  }
})

test_that("references.bib carries no at-sign outside an entry", {
  bib <- readLines(file.path(syllabus_dir(), "references.bib"), warn = FALSE)
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
  offenders <- grep("[^`]Table @tbl-", skeleton_qmd(), value = TRUE)
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
  expect_true(file.exists(file.path(dir, "references.bib")))

  # The syllabus selects `format: qkit-syllabus-pdf`, so the extension has to
  # be installed alongside it or the render fails with an unknown format.
  expect_true(dir.exists(file.path(dir, "_extensions", "qkit-syllabus")))
  expect_true(file.exists(file.path(dir, "_extensions", "qkit-syllabus",
                                    "before-body.tex")))
  # ...and only that one: a syllabus has no use for the CV or beamer format.
  expect_false(dir.exists(file.path(dir, "_extensions", "qkit")))

  lines <- readLines(file.path(dir, "index.qmd"), warn = FALSE)
  # The course-code prefix survives; only the trailing half is replaced.
  expect_true(any(grepl('title: "ECON 000 --- Python for Finance"',
                        lines, fixed = TRUE)))
  expect_true(any(grepl('author: "Ada Lovelace"', lines, fixed = TRUE)))
  expect_false(any(grepl("Your Course Title", lines, fixed = TRUE)))
  expect_false(any(grepl("Your Name", lines, fixed = TRUE)))
})
