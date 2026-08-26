#' Install the qkit Quarto extensions
#'
#' Copies the bundled Quarto extension directories into a project, making
#' their formats available to `format:` in a document's YAML.
#'
#' Two extensions ship with the package:
#'
#' * `qkit` — contributes `qkit-beamer` and `qkit-pdf` (the CV).
#' * `qkit-syllabus` — contributes `qkit-syllabus-pdf`.
#'
#' They are separate directories because Quarto allows a directory only one
#' format per base format, and `qkit` already claims `pdf` for the CV.
#'
#' @param path Path to the project directory. Defaults to the current
#'   working directory.
#' @param which Which extensions to install. Defaults to all bundled ones;
#'   pass `"qkit"` or `"qkit-syllabus"` to install just one.
#' @param overwrite If `TRUE`, overwrite an extension that is already
#'   installed. Defaults to `FALSE`.
#'
#' @return Invisibly returns the installed target directories.
#' @export
install_extension <- function(path = ".", which = NULL, overwrite = FALSE) {

  root <- system.file("extdata", "_extensions", package = "qkit", mustWork = TRUE)
  available <- basename(fs::dir_ls(root, type = "directory"))

  if (is.null(which)) {

    which <- available

  } else {

    unknown <- setdiff(which, available)

    if (length(unknown)) {

      stop("Unknown qkit extension(s): ", paste(unknown, collapse = ", "),
           ". Available: ", paste(available, collapse = ", "), call. = FALSE)

    }

  }

  fs::dir_create(fs::path(path, "_extensions"))
  targets <- character(0)

  for (ext in which) {

    target <- fs::path(path, "_extensions", ext)

    if (fs::dir_exists(target) && !overwrite) {

      message("qkit extension '", ext, "' already installed at '", target,
              "'. Use overwrite = TRUE to reinstall.")

      targets <- c(targets, target)
      next

    }

    fs::dir_copy(fs::path(root, ext), target, overwrite = overwrite)
    message("qkit extension '", ext, "' installed to '", target, "'.")
    targets <- c(targets, target)

  }

  invisible(targets)

}
