#' Render a qkit Quarto document
#'
#' Wrapper around `quarto::quarto_render()` that automatically installs the
#' required qkit extension if not present, then renders the document.
#'
#' @param input Path to the `.qmd` file to render.
#' @param ... Additional arguments passed to `quarto::quarto_render()`.
#'
#' @return The return value of `quarto::quarto_render()`.
#' @export
qkit_render <- function(input, ...) {

  ensure_extension(input)

  if (!requireNamespace("quarto", quietly = TRUE)) {

    stop("Package 'quarto' is required. Install it with install.packages('quarto').",
         call. = FALSE)

  }

  quarto::quarto_render(input, ...)

}

#' Preview a qkit Quarto document
#'
#' Wrapper around `quarto::quarto_preview()` that automatically installs the
#' required qkit extension if not present, then starts the preview.
#'
#' @param input Path to the `.qmd` file to preview.
#' @param ... Additional arguments passed to `quarto::quarto_preview()`.
#'
#' @return The return value of `quarto::quarto_preview()`.
#' @export
qkit_preview <- function(input, ...) {

  ensure_extension(input)

  if (!requireNamespace("quarto", quietly = TRUE)) {

    stop("Package 'quarto' is required. Install it with install.packages('quarto').",
         call. = FALSE)

  }

  quarto::quarto_preview(input, ...)

}

#' Detect qkit base formats referenced in a Quarto document's YAML
#'
#' @param input Path to a `.qmd` file.
#' @return Character vector of detected qkit base formats (subset of
#'   `c("beamer", "pdf")`). Empty if no qkit format is referenced or
#'   if the front matter cannot be parsed.
#' @noRd
detect_qkit_formats <- function(input) {

  lines <- tryCatch(readLines(input, warn = FALSE, encoding = "UTF-8"), error = function(e) character(0))
  fence <- which(lines == "---")
  if (length(fence) < 2) return(character(0))
  yaml_text <- paste(lines[(fence[[1]] + 1):(fence[[2]] - 1)], collapse = "\n")
  meta <- tryCatch(yaml::yaml.load(yaml_text), error = function(e) NULL)
  if (is.null(meta) || is.null(meta$format)) return(character(0))

  fmt <- meta$format
  keys <- if (is.character(fmt)) {

    fmt

  } else if (is.list(fmt)) {

    # YAML map: format: { qkit-beamer: default, ... } → take names.
    # YAML sequence: format: [qkit-beamer, html] parses as an unnamed list of
    # character entries → take values too. Cover both shapes.
    c(names(fmt), unlist(fmt[vapply(fmt, is.character, logical(1))], use.names = FALSE))

  } else {

    character(0)

  }

  keys <- keys[!is.na(keys) & nzchar(keys)]

  prefix <- "qkit-"
  hits <- keys[startsWith(keys, prefix)]
  types <- substring(hits, nchar(prefix) + 1L)
  types <- types[types %in% c("beamer", "pdf")]

  unique(types)

}

#' Auto-install the qkit extension when referenced by a Quarto file
#'
#' Inspects the YAML front matter of `input`. If any `qkit-*` format is
#' referenced and `_extensions/qkit/` is missing next to `input`,
#' installs it.
#'
#' Silent no-op if no qkit format is referenced or the YAML cannot
#' be parsed — Quarto will report any actual error.
#'
#' @param input Path to a `.qmd` file.
#' @noRd
ensure_extension <- function(input) {

  types <- detect_qkit_formats(input)
  if (length(types) == 0L) return(invisible(FALSE))

  project_dir <- fs::path_dir(fs::path_abs(input))

  if (!fs::dir_exists(fs::path(project_dir, "_extensions", "qkit"))) {

    install_extension(path = project_dir)

  }

  invisible(TRUE)
  
}
