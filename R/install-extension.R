#' Install the qkit Quarto extension
#'
#' Copies the qkit Quarto extension files into a project directory,
#' making the `qkit-beamer` and `qkit-pdf` formats available.
#'
#' @param path Path to the project directory. Defaults to the current
#'   working directory.
#' @param overwrite If `TRUE`, overwrite the existing extension.
#'   Defaults to `FALSE`.
#'
#' @return Invisibly returns the installed target directory.
#' @export
install_extension <- function(path = ".", overwrite = FALSE) {
  target <- fs::path(path, "_extensions", "qkit")
  if (fs::dir_exists(target) && !overwrite) {
    message("qkit extension already installed at '", target,
            "'. Use overwrite = TRUE to reinstall.")
    return(invisible(target))
  }
  fs::dir_create(fs::path(path, "_extensions"))
  source <- system.file("extdata", "_extensions", "qkit",
                        package = "qkit", mustWork = TRUE)
  fs::dir_copy(source, target, overwrite = overwrite)
  message("qkit extension installed to '", target, "'.")
  invisible(target)
}
