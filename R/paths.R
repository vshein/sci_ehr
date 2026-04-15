# ==============================================================================
# paths.R — Project paths, credentials, and configuration loading
# ==============================================================================

#' Build the full set of project paths for a given source.
#'
#' Data paths (download, cohort FST, generated SQL) are relative to
#' \code{base_dir}.  SQL templates and bundled config files are read from the
#' installed package via \code{system.file()}.
#'
#' @param base_dir Root directory for this user's data files.
#' @param src_name Source identifier, e.g. \code{"miii_demo"}, \code{"miiv_demo"},
#'   or \code{"eicu_demo"}.
#' @param concept_config_name File name of the concept config CSV inside
#'   \code{inst/config/}.  Defaults to \code{"concept_config.csv"}.
#' @return A named list of paths.
#' @export
make_project_paths <- function(base_dir, src_name,
                               concept_config_name = "concept_config.csv") {
  pkg      <- "sciehr"
  pkg_sql  <- system.file("sql", src_name, package = pkg)
  pkg_cfg  <- system.file("config",        package = pkg)

  # Fallback for development without installation (devtools::load_all)
  if (!nzchar(pkg_sql)) {
    pkg_sql <- file.path(find.package(pkg, quiet = TRUE), "inst", "sql", src_name)
  }
  if (!nzchar(pkg_cfg)) {
    pkg_cfg <- file.path(find.package(pkg, quiet = TRUE), "inst", "config")
  }

  list(
    # ---- user data dirs (written during a run) ----
    base_dir       = base_dir,
    raw_dir        = file.path(base_dir, "data", "physionet_data", src_name),
    cohort_fst_dir = file.path(base_dir, "data", "cohorts_data",
                               paste0(src_name, "_fst")),
    sql_out_dir    = file.path(base_dir, "sql_output", src_name),

    # ---- package SQL templates ----
    sql_dir            = pkg_sql,
    schema_sql_dir     = file.path(pkg_sql, "db_setup_sqls", "schema"),
    helper_sql_dir     = file.path(pkg_sql, "db_setup_sqls"),
    flat_sql_dir       = file.path(pkg_sql, "concepts_sqls", "flat"),
    duration_sql_dir   = file.path(pkg_sql, "concepts_sqls", "duration"),
    timeseries_sql_dir = file.path(pkg_sql, "concepts_sqls", "timeseries"),

    # ---- package config ----
    config_dir         = pkg_cfg,
    data_config_json   = file.path(pkg_cfg, "data-sources.json"),
    concept_config_csv = file.path(pkg_cfg, concept_config_name),

    # ---- user-managed credentials (never in the package) ----
    credentials_json   = file.path(base_dir, "config", "config_pass.json")
  )
}


#' Create any missing user-data directories for a project.
#'
#' @inheritParams make_project_paths
#' @return The paths list, invisibly.
#' @export
initialize_project <- function(base_dir, src_name) {
  paths <- make_project_paths(base_dir, src_name)
  dirs  <- c(paths$raw_dir, paths$cohort_fst_dir, paths$sql_out_dir)
  for (d in dirs) dir.create(d, recursive = TRUE, showWarnings = FALSE)
  message("Project directories initialized for '", src_name, "'.")
  invisible(paths)
}


#' Load credentials from a JSON file.
#'
#' Expected structure: \code{list(physionet = list(username, password),
#' postgres = list(password))}.
#'
#' @param path Path to the credentials JSON file.
#' @return A named list.
#' @export
load_credentials <- function(path = file.path("config", "config_pass.json")) {
  if (!file.exists(path)) {
    stop("Credentials file not found: ", path,
         "\nCreate it with physionet and postgres entries.")
  }
  jsonlite::read_json(path, simplifyVector = TRUE)
}


#' Set PhysioNet credentials as environment variables.
#'
#' @param creds Credentials list from \code{\link{load_credentials}}.
#' @export
set_physionet_env <- function(creds) {
  Sys.setenv(
    RICU_PHYSIONET_USER = creds$physionet$username %||% "",
    RICU_PHYSIONET_PASS = creds$physionet$password %||% ""
  )
}


#' Load a single source's configuration block from the data-sources JSON.
#'
#' @param json_path Path to the data-sources JSON file.
#' @param src_name  Source name to look up.
#' @return A list with keys such as \code{url}, \code{tables}, etc.
#' @export
load_src_config <- function(json_path, src_name) {
  all_cfg <- jsonlite::fromJSON(json_path, simplifyVector = FALSE)
  for (entry in all_cfg) {
    if (identical(entry$name, src_name)) return(entry)
  }
  available <- vapply(all_cfg, function(e) e$name %||% "???", character(1L))
  stop("Source '", src_name, "' not found in JSON. Available: ",
       paste(available, collapse = ", "))
}
