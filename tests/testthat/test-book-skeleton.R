# Tests for the book skeleton's _quarto.yml. Both guarded settings were live
# bugs: papersize failed silently (the book rendered on letter instead of A4),
# and the block-scalar subtitle failed loudly (no PDF at all).

book_yaml <- function() {
  src <- "../../inst/rstudio/templates/project/skeleton/book/_quarto.yml"
  if (file.exists(src)) return(src)
  installed <- system.file(
    "rstudio/templates/project/skeleton/book/_quarto.yml", package = "qkit"
  )
  testthat::skip_if(identical(installed, ""), "book skeleton not found")
  installed
}

test_that("book papersize is a bare size, not a *paper name", {
  # Quarto appends "paper" itself, so "a4paper" reaches krantz.cls as
  # "a4paperpaper", an unknown option it ignores without complaint.
  pdf <- yaml::read_yaml(book_yaml())$format$pdf
  expect_false(grepl("paper$", pdf$papersize))
})

test_that("book pins display-equation spacing", {
  # Same empty-paragraph bug as the paper and beamer preambles: without the
  # fix a display sits 8pt further from the text above it than below.
  header <- yaml::read_yaml(book_yaml())$format$pdf$`include-in-header`$text
  expect_true(grepl("qkitdisplayfix", header, fixed = TRUE))
  expect_true(grepl("BeforeBeginEnvironment{equation}", header, fixed = TRUE))
})

test_that("the demo chapters and their figure asset ship", {
  d <- dirname(book_yaml())
  expect_true(file.exists(file.path(d, "example-figure.pdf")))
  for (f in c("chapter1.qmd", "chapter2.qmd")) {
    expect_true(file.exists(file.path(d, f)), info = paste(f, "is missing"))
  }
})

test_that("book subtitle is a single line", {
  # before-body.tex opens a group with the subtitle, so a newline in it
  # reaches LaTeX as a leading \\ and the render dies with
  # "There's no line here to end".
  subtitle <- yaml::read_yaml(book_yaml())$book$subtitle
  expect_length(subtitle, 1L)
  expect_false(grepl("\n", subtitle, fixed = TRUE))
})
