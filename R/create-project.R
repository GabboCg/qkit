#' Create a new qkit project
#'
#' Scaffolds a Quarto project of the requested type:
#'   * `"beamer"` — a single-file Beamer presentation (uses the qkit
#'     extension for styling),
#'   * `"cv"` — a single-file academic CV (uses the qkit extension),
#'   * `"book"` — a multi-file Quarto book project with the Krantz
#'     document class, generic title-page partial, sample chapters,
#'     and a bibliography stub (self-contained — does NOT install the
#'     qkit extension because all book styling lives in the project's
#'     own `_quarto.yml` and template-partials),
#'   * `"paper"` — a minimalist Quarto academic paper (12pt article,
#'     1in margins, double-spaced body, one-and-a-half-spaced title,
#'     italic subsection headings, period-after-section numbering,
#'     citeproc bibliography) bundled with a separate Internet
#'     Appendix file (`internet-appendix.qmd`), two `.bib` stubs,
#'     and two LaTeX preamble files.
#'   * `"syllabus"` — a course syllabus (11pt article, Palatino, 1in
#'     margins, unnumbered sections, running head, page x/y footer)
#'     with a course-information block driven from YAML and a
#'     natbib reading list (also self-contained — no extension).
#'
#' @param path Path to the new project directory.
#' @param type One of `"beamer"`, `"cv"`, `"book"`, `"paper"`,
#'   `"syllabus"`. Defaults to `"beamer"`.
#' @param title Presentation / book / paper / course title (used when
#'   `type` is `"beamer"`, `"book"`, `"paper"`, or `"syllabus"`).
#' @param author Author name (used when `type` is `"cv"`, `"book"`, or
#'   `"syllabus"`). For `"paper"` the YAML carries a structured author
#'   list (with ORCID, email, affiliations); edit `index.qmd` after
#'   scaffolding.
#' @param ... Additional arguments passed by RStudio (ignored).
#'
#' @return Invisibly returns the project path.
#' @export
create_project <- function(path,
                           type = "beamer",
                           title = "Untitled Presentation",
                           author = "Your Name",
                           ...) {
  # Guard against RStudio's wizard passing path as NA / "" / NULL, which
  # would silently coerce downstream fs::path() calls into the literal
  # string "NA" and write skeleton files into the parent directory.
  if (is.null(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {

    stop("create_project() requires a non-empty 'path' argument. Got: ",
         deparse(path), call. = FALSE)

  }
  type <- match.arg(type, choices = c("beamer", "cv", "book", "paper", "syllabus"))
  fs::dir_create(path)

  # Substitute placeholders only when the caller supplied a usable value.
  # RStudio passes empty wizard fields as NA; gsub() with replacement = NA
  # silently writes the literal string "NA" into the document.
  usable <- function(x) !is.null(x) && length(x) == 1L && !is.na(x) && nzchar(x)

  if (type %in% c("book", "paper", "syllabus")) {

    src <- system.file("rstudio", "templates", "project", "skeleton",
                       type, package = "qkit", mustWork = TRUE)
    files <- fs::dir_ls(src, recurse = TRUE, type = "file")

    for (f in files) {

      rel <- fs::path_rel(f, src)
      target <- fs::path(path, rel)
      fs::dir_create(fs::path_dir(target))
      fs::file_copy(f, target, overwrite = FALSE)

    }
    # Patch placeholders in the entry file(s):
    #   * book: `_quarto.yml` (title + author both substituted)
    #   * paper: `index.qmd` and `internet-appendix.qmd` (title only;
    #     authors live in a structured YAML block edited by hand
    #     after scaffolding — there's no "Your Name" placeholder to
    #     substitute into)
    #   * syllabus: `index.qmd` (title + author; the course title
    #     placeholder carries the "ECON 000 — " course-code prefix, so
    #     substituting only the trailing half keeps that prefix for the
    #     user to edit)
    title_placeholder <- switch(type,
      book = "Your Book Title",
      paper = "Your Paper Title",
      syllabus = "Your Course Title"
    )

    entries <- switch(type,
      book = fs::path(path, "_quarto.yml"),
      paper = c(fs::path(path, "index.qmd"),
                fs::path(path, "internet-appendix.qmd")),
      syllabus = fs::path(path, "index.qmd")
    )

    for (entry in entries) {

      if (!fs::file_exists(entry)) next
      content <- readLines(entry, encoding = "UTF-8")
      if (usable(title)) content <- gsub(title_placeholder, title, content, fixed = TRUE)
      if (type %in% c("book", "syllabus") && usable(author)) {

        content <- gsub("Your Name", author, content, fixed = TRUE)

      }

      writeLines(content, entry, useBytes = TRUE)

    }

    return(invisible(path))

  }

  # beamer / cv: single-file skeleton + install the qkit extension.
  skeleton_name <- paste0(type, ".qmd")
  skeleton <- system.file("rstudio", "templates", "project", "skeleton",
                          skeleton_name, package = "qkit", mustWork = TRUE)
  content <- readLines(skeleton, encoding = "UTF-8")

  if (type == "beamer" && usable(title)) {

    content <- gsub("Untitled Presentation", title, content, fixed = TRUE)

  } else if (type == "cv" && usable(author)) {

    content <- gsub("Your Name", author, content, fixed = TRUE)
    
  }

  writeLines(content, fs::path(path, "index.qmd"), useBytes = TRUE)
  install_extension(path = path)

  invisible(path)
  
}
