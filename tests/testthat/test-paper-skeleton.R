# Tests that the paper skeleton ships the float-note machinery and wires it
# into both documents. The failure mode being guarded is silent: if
# float-notes.lua is missing from a document's `filters:` key, every note=
# attribute is dropped without any render error. The longtable assertion
# guards the same class of bug -- the hook was fixed in preamble.tex by
# d74d90f but not in preamble-appendix.tex, and nothing caught it.

paper_dir <- function() {
  src <- "../../inst/rstudio/templates/project/skeleton/paper"
  if (dir.exists(src)) return(src)
  installed <- system.file(
    "rstudio/templates/project/skeleton/paper", package = "qkit"
  )
  testthat::skip_if(identical(installed, ""), "paper skeleton not found")
  installed
}

test_that("paper skeleton ships float-notes.lua and the demo asset", {
  d <- paper_dir()
  expect_true(file.exists(file.path(d, "float-notes.lua")))
  expect_true(file.exists(file.path(d, "example-figure.pdf")))
})

test_that("both paper documents register float-notes.lua", {
  d <- paper_dir()
  for (f in c("index.qmd", "internet-appendix.qmd")) {
    lines <- readLines(file.path(d, f), warn = FALSE)
    expect_true(
      any(grepl("float-notes.lua", lines, fixed = TRUE)),
      info = paste(f, "does not register float-notes.lua")
    )
  }
})

test_that("both preambles define the floatnote macro", {
  d <- paper_dir()
  for (f in c("preamble.tex", "preamble-appendix.tex")) {
    tex <- readLines(file.path(d, f), warn = FALSE)
    expect_true(
      any(grepl("newcommand{\\floatnote}", tex, fixed = TRUE)),
      info = paste(f, "does not define \\floatnote")
    )
  }
})

test_that("both preambles hook longtable as well as tabular", {
  d <- paper_dir()
  for (f in c("preamble.tex", "preamble-appendix.tex")) {
    tex <- readLines(file.path(d, f), warn = FALSE)
    expect_true(
      any(grepl("AtBeginEnvironment{longtable}", tex, fixed = TRUE)),
      info = paste(f, "does not hook longtable")
    )
  }
})

test_that("both preambles cancel the empty paragraph above a display", {
  # Same two-preamble parity bug as the longtable hook: preamble-appendix.tex
  # only pinned the four display skips, so its equations kept the extra
  # \baselineskip that TeX contributes above a display begun in vertical mode.
  d <- paper_dir()
  for (f in c("preamble.tex", "preamble-appendix.tex")) {
    tex <- readLines(file.path(d, f), warn = FALSE)
    expect_true(
      any(grepl("newcommand{\\qkitdisplayfix}", tex, fixed = TRUE)),
      info = paste(f, "does not define \\qkitdisplayfix")
    )
    expect_true(
      any(grepl("BeforeBeginEnvironment{equation}{\\qkitdisplayfix}",
                tex, fixed = TRUE)),
      info = paste(f, "does not hook equation with \\qkitdisplayfix")
    )
  }
})

test_that("both preambles set the journal caption style", {
  d <- paper_dir()
  for (f in c("preamble.tex", "preamble-appendix.tex")) {
    tex <- readLines(file.path(d, f), warn = FALSE)
    expect_true(
      any(grepl("labelsep=period", tex, fixed = TRUE)),
      info = paste(f, "does not set labelsep=period")
    )
  }
})
