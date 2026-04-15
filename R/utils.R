# ==============================================================================
# utils.R — Low-level utility functions
# ==============================================================================

#' Null-coalescing operator
#' @param x Left-hand value.
#' @param y Right-hand fallback.
#' @export
`%||%` <- function(x, y) if (is.null(x)) y else x

not_null <- function(x) !is.null(x)

sys_env <- function(...) Sys.getenv(...)

is_interactive <- function() {
  !isTRUE(getOption("knitr.in.progress")) && interactive()
}

# Internal coalesce (distinct from dplyr::coalesce)
.coalesce <- function(...) {
  for (arg in list(...)) {
    if (!is.null(arg)) return(arg)
  }
  NULL
}

ensure_dirs <- function(paths) {
  uq_paths <- unique(paths)
  is_dir   <- file.info(uq_paths, extra_cols = FALSE)[["isdir"]]
  is_no_dir <- vapply(is_dir, identical, logical(1L), FALSE)
  if (any(is_no_dir)) {
    stop("Paths exist but are not directories: ",
         paste(uq_paths[is_no_dir], collapse = ", "))
  }
  to_create <- uq_paths[is.na(is_dir)]
  if (length(to_create) > 0L) {
    res <- vapply(to_create, dir.create, logical(1L), recursive = TRUE)
    if (!all(res)) {
      stop("Could not create directories: ",
           paste(to_create[!res], collapse = ", "))
    }
  }
  invisible(paths)
}

msg_ricu  <- function(...) message(...)
warn_ricu <- function(msg, ...) warning(msg, call. = FALSE)
stop_ricu <- function(msg, ...) stop(msg, call. = FALSE)
read_line <- function(prompt = "") readline(prompt)

rename_cols <- function(x, new, old = colnames(x), skip_absent = FALSE,
                        by_ref = FALSE) {
  if (skip_absent) {
    present <- old %in% colnames(x)
    new <- new[present]
    old <- old[present]
  }
  if (length(new) == 0L) return(x)
  if (by_ref && inherits(x, "data.table")) {
    data.table::setnames(x, old, new)
  } else {
    idx <- match(old, colnames(x))
    colnames(x)[idx[!is.na(idx)]] <- new[!is.na(idx)]
  }
  x
}

report_problems <- function(x, file) {
  if (requireNamespace("readr", quietly = TRUE)) {
    probs <- readr::problems(x)
    if (nrow(probs) > 0) {
      warning("Problems parsing ", file, ": ", nrow(probs), " issues",
              call. = FALSE)
    }
  }
  invisible(NULL)
}

parse_headers <- function(headers) {
  if (is.raw(headers)) headers <- rawToChar(headers)
  strsplit(headers, "\r\n")[[1]]
}

progress_init <- function(length = NULL, msg = "loading", ...) {
  if (is_interactive() && requireNamespace("progress", quietly = TRUE) &&
      !is.null(length) && length > 1L) {
    res <- progress::progress_bar$new(
      format = ":what [:bar] :percent", total = length, ...
    )
  } else {
    res <- NULL
  }
  if (!is.null(msg)) message(msg)
  res
}

progress_tick <- function(info = NULL, progress_bar = NULL, length = 1L) {
  if (isFALSE(progress_bar)) return(invisible(NULL))
  if (is.null(progress_bar)) {
    if (!is.null(info)) message("  - ", info)
    return(invisible(NULL))
  }
  if (inherits(progress_bar, "progress_bar")) {
    progress_bar$tick(len = length, tokens = list(what = info %||% ""))
  }
  invisible(NULL)
}

with_progress <- function(expr, progress_bar = NULL) {
  res <- expr
  if (inherits(progress_bar, "progress_bar") && !progress_bar$finished) {
    progress_bar$update(1)
  }
  res
}

warn_dots <- function(..., ok_args = NULL) {
  if (...length() > 0L) {
    args <- setdiff(names(match.call(expand.dots = FALSE)$`...`), ok_args)
    if (length(args) > 0) {
      warning("Ignoring unexpected argument(s): ",
              paste(args, collapse = ", "), call. = FALSE)
    }
  }
  invisible(NULL)
}

dbl_ply <- function(x, fun, ...) vapply(x, fun, numeric(1L), ...)

get_cred <- function(x, env, msg) {
  if (is.null(x)) {
    x <- sys_env(env, unset = NA_character_)
    if (is.na(x)) {
      if (!is_interactive()) stop_ricu("User input is required")
      x <- read_line(msg)
    }
  }
  x
}
