# Tests for the bundled beamer format's preamble. Every failure mode guarded
# here is silent in the render: the deck still builds, it just looks wrong.

beamer_preamble <- function() {
  src <- "../../inst/extdata/_extensions/qkit/beamer/preamble.tex"
  if (file.exists(src)) return(src)
  installed <- system.file(
    "extdata/_extensions/qkit/beamer/preamble.tex", package = "qkit"
  )
  testthat::skip_if(identical(installed, ""), "beamer preamble not found")
  installed
}

test_that("the beamer preamble overrides Pandoc's tightlist", {
  # Pandoc emits \tightlist inside nearly every list and its default
  # definition zeroes \itemsep, so any list spacing set on the way into the
  # environment is undone a token later. The template must redefine it.
  tex <- readLines(beamer_preamble(), warn = FALSE)
  expect_true(
    any(grepl("renewcommand{\\tightlist}", tex, fixed = TRUE)),
    info = "preamble does not redefine \\tightlist"
  )
  expect_true(
    any(grepl("\\qkitlistsep", tex, fixed = TRUE)),
    info = "preamble does not define a list-separation length"
  )
})

test_that("the beamer preamble cancels the empty paragraph above a display", {
  # Same fix as the paper preambles: Pandoc emits a display as its own block,
  # so LaTeX opens an empty paragraph above it and contributes a stray
  # \baselineskip that nothing below the display matches.
  tex <- readLines(beamer_preamble(), warn = FALSE)
  expect_true(
    any(grepl("newcommand{\\qkitdisplayfix}", tex, fixed = TRUE)),
    info = "preamble does not define \\qkitdisplayfix"
  )
  expect_true(
    any(grepl("BeforeBeginEnvironment{equation}{\\qkitdisplayfix}",
              tex, fixed = TRUE)),
    info = "preamble does not hook equation with \\qkitdisplayfix"
  )
})

test_that("the beamer preamble wraps long code lines", {
  # A slide is ~46 characters wide; without breaklines a longer code line
  # runs off the right edge of the frame and off the page.
  tex <- readLines(beamer_preamble(), warn = FALSE)
  expect_true(
    any(grepl("breaklines=true", tex, fixed = TRUE)),
    info = "preamble does not set fancyvrb breaklines"
  )
})
