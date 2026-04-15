# ==============================================================================
# pipeline.R — High-level pipeline runners
# ==============================================================================

# ---- Internal helpers -------------------------------------------------------

.download_if_needed <- function(src_name, cfg, paths, creds) {
  user <- creds$physionet$username %||% ""
  pass <- creds$physionet$password %||% ""

  if (!nzchar(user) || !nzchar(pass)) {
    message("PhysioNet credentials missing – skipping download.")
    return(invisible(NULL))
  }

  download_data(
    src_name    = src_name,
    tables      = names(cfg$tables),
    data_dir    = paths$raw_dir,
    config_path = paths$data_config_json
  )
}


# ---- TS / flat / duration table builders ------------------------------------

#' Build a long-format time-series table from per-concept concept tables.
#'
#' @param con           A DBI connection.
#' @param schema_names  Schema names list from \code{\link{src_schema_names}}.
#' @param concept_names Character vector of concept table names.
#' @param table_name    Name for the output table.
#' @param icu_stay_col  ICU stay column name.
#' @export
build_ts_table <- function(con, schema_names, concept_names,
                           table_name = "ts_tab", icu_stay_col = "stay_id") {
  union_parts <- sprintf(
    paste0("SELECT source_dataset, subject_id, hadm_id, %s,",
           " offset_min, '%s' AS variable, value, unit",
           " FROM %s.%s"),
    icu_stay_col,
    concept_names,
    schema_names$concepts,
    concept_names
  )

  sql <- glue::glue("
DROP TABLE IF EXISTS {schema_names$ts}.{table_name};
CREATE TABLE {schema_names$ts}.{table_name} AS
{paste(union_parts, collapse = '\nUNION ALL\n')};
")
  DBI::dbExecute(con, sql, immediate = TRUE)
  invisible(NULL)
}


#' Build a wide-format flat table by joining per-concept flat tables.
#'
#' @param con           A DBI connection.
#' @param schema_names  Schema names list from \code{\link{src_schema_names}}.
#' @param flat_concepts Character vector of flat concept table names.
#' @param table_name    Name for the output table.
#' @param icu_stay_col  ICU stay column name.
#' @export
build_flat_table <- function(con, schema_names, flat_concepts,
                             table_name = "flat_tab",
                             icu_stay_col = "stay_id") {
  select_cols <- paste0(flat_concepts, ".", flat_concepts, collapse = ",\n    ")

  joins <- paste0(
    "LEFT JOIN ", schema_names$concepts, ".", flat_concepts, " ", flat_concepts,
    " USING (subject_id, hadm_id, ", icu_stay_col, ")",
    collapse = "\n"
  )

  sql <- glue::glue("
DROP TABLE IF EXISTS {schema_names$flat}.{table_name};
CREATE TABLE {schema_names$flat}.{table_name} AS
SELECT
  '{schema_names$raw}' AS source_data,
  base.subject_id,
  base.hadm_id,
  base.{icu_stay_col},
  {select_cols}
FROM {schema_names$raw}.visit_windows base
{joins};
")
  DBI::dbExecute(con, sql, immediate = TRUE)
  invisible(NULL)
}


#' Build a UNION ALL query across several source schemas.
#'
#' @param con            A DBI connection.
#' @param source_schemas Character vector of schema names.
#' @param table_name     Table name present in each schema.
#' @return A single SQL string.
get_union_sql <- function(con, source_schemas, table_name) {
  parts <- sprintf("SELECT * FROM %s.%s", source_schemas, table_name)
  paste(parts, collapse = "\nUNION ALL\n")
}


#' Merge a table from multiple source schemas into a single target table.
#'
#' @param con               A DBI connection.
#' @param source_schemas    Character vector of source schema names.
#' @param table_name        Table name in each source schema.
#' @param target_schema     Schema for the output table.
#' @param target_table_name Output table name.
#' @export
merge_source_tables <- function(con, source_schemas, table_name,
                                target_schema, target_table_name) {
  union_sql <- get_union_sql(con, source_schemas, table_name)
  sql <- glue::glue("
DROP TABLE IF EXISTS {target_schema}.{target_table_name};
CREATE TABLE {target_schema}.{target_table_name} AS
{union_sql};
")
  DBI::dbExecute(con, sql, immediate = TRUE)
  invisible(NULL)
}


# ---- Main pipeline runners --------------------------------------------------

#' Run the full source ingestion pipeline for a single EHR source.
#'
#' Covers all 12 stages:
#' \enumerate{
#'   \item Load config and paths
#'   \item Credentials and DB connection
#'   \item Download raw data (if credentials present)
#'   \item Import CSV → FST
#'   \item Build cohort subject IDs
#'   \item Subset raw FST to cohort
#'   \item Create database schemas and base tables
#'   \item Load FST → PostgreSQL
#'   \item Add ICD lookup and visit-window tables
#'   \item Build atomic TS concepts from config
#'   \item Run handcrafted flat / duration SQL
#' }
#'
#' @param src_name            Source identifier, e.g. \code{"miii_demo"},
#'   \code{"miiv_demo"}, \code{"eicu_demo"}.
#' @param db_name             PostgreSQL database name.
#' @param base_dir            User project root directory.
#' @param icds_scid_path      Path to CSV with SCI ICD codes (column \code{icd_code}).
#' @param icds_inj_path       Path to CSV with injury ICD codes.
#' @param concept_config_name Filename of the concept config CSV.  Resolved as:
#'   user \code{base_dir/config/<name>} > package default.
#' @param concept_config_path Optional explicit full path to a concept config CSV.
#'   Overrides \code{concept_config_name} resolution entirely.
#' @param host PostgreSQL host.
#' @param port PostgreSQL port.
#' @export
run_source_pipeline <- function(src_name, db_name, base_dir,
                                icds_scid_path, icds_inj_path,
                                concept_config_name = "concept_config.csv",
                                concept_config_path = NULL,
                                host = "localhost", port = 5432) {
  paths        <- make_project_paths(base_dir, src_name,
                                     concept_config_name = concept_config_name,
                                     concept_config_path = concept_config_path)
  schema_names <- src_schema_names(src_name)
  icu_stay_col <- get_icu_stay_col(src_name)

  creds <- load_credentials(paths$credentials_json)
  set_physionet_env(creds)

  ensure_database_exists(db_name, creds, host = host, port = port)
  con <- connect_postgres(db_name, creds, host = host, port = port)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  cfg <- load_src_config(paths$data_config_json, src_name)

  # Stage 2–3: Download + import
  .download_if_needed(src_name, cfg, paths, creds)
  import_data(src_name, names(cfg$tables), paths$raw_dir, paths$data_config_json)

  # Stage 4–5: Cohort
  cohort_ids <- build_cohort_ids(paths, icds_scid_path, src_name = src_name)
  subset_source_to_cohort(paths, cohort_ids, key = "subject_id")

  # Stage 6–8: DB setup
  create_schemas(con, schema_names)
  DBI::dbExecute(con, glue::glue("SET search_path TO {schema_names$raw};"))
  run_sql_dir(con, paths$schema_sql_dir)

  convert_fst_to_psql(
    fst_dir = paths$cohort_fst_dir,
    con     = con,
    schema  = schema_names$raw,
    overwrite = TRUE
  )

  # Stage 8: Helper tables (ICD dicts + visit_windows)
  add_scid_tables(
    con            = con,
    paths          = paths,
    schema_names   = schema_names,
    icds_scid_path = icds_scid_path,
    icds_inj_path  = icds_inj_path
  )

  # Stage 9: Atomic concepts
  run_atomic_concepts(
    con                 = con,
    concept_config_path = paths$concept_config_csv,
    src_name            = schema_names$raw,
    schema_names        = schema_names,
    typ                 = "ts",
    sql_out_dir         = paths$sql_out_dir,
    icu_stay_col        = icu_stay_col
  )

  # Stage 10: Handcrafted flat / duration SQL
  run_handcrafted_concepts(con, paths)

  message("Pipeline complete for: ", src_name)
  invisible(TRUE)
}


#' Build harmonized time-series and flat tables for a single source.
#'
#' Reads the concept config to discover TS concept names automatically, then
#' builds the \code{ts_tab} (long format) and \code{flat_tab} (wide format)
#' tables in the source's schemas.
#'
#' @param src_name         Source identifier.
#' @param db_name          PostgreSQL database name.
#' @param base_dir         User project root directory.
#' @param flat_concepts    Character vector of flat concept names to include in
#'   the wide table.  Pass \code{NULL} to skip.
#' @param build_ts         Build the time-series table?
#' @param build_flat       Build the flat table?
#' @param build_dur        Build the duration table? (not yet implemented)
#' @param ts_table_name    Name for the TS output table.
#' @param flat_table_name  Name for the flat output table.
#' @param dur_table_name   Name for the duration output table (future use).
#' @param concept_config_name Filename of the concept config CSV.  Resolved as:
#'   user \code{base_dir/config/<name>} > package default.
#' @param concept_config_path Optional explicit full path to a concept config CSV.
#'   Overrides \code{concept_config_name} resolution entirely.
#' @param host PostgreSQL host.
#' @param port PostgreSQL port.
#' @export
run_harmonized_tables <- function(src_name, db_name, base_dir,
                                  flat_concepts     = NULL,
                                  build_ts          = TRUE,
                                  build_flat        = TRUE,
                                  build_dur         = FALSE,
                                  ts_table_name     = "ts_tab",
                                  flat_table_name   = "flat_tab",
                                  dur_table_name    = "dur_tab",
                                  concept_config_name = "concept_config.csv",
                                  concept_config_path = NULL,
                                  host = "localhost", port = 5432) {
  paths        <- make_project_paths(base_dir, src_name,
                                     concept_config_name = concept_config_name,
                                     concept_config_path = concept_config_path)
  schema_names <- src_schema_names(src_name)
  icu_stay_col <- get_icu_stay_col(src_name)

  creds <- load_credentials(paths$credentials_json)
  set_physionet_env(creds)

  ensure_database_exists(db_name, creds, host = host, port = port)
  con <- connect_postgres(db_name, creds, host = host, port = port)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  concept_cfg <- readr::read_csv(paths$concept_config_csv, show_col_types = FALSE)

  # Build TS table
  if (build_ts) {
    ts_concepts <- concept_cfg |>
      dplyr::filter(source == schema_names$raw, typ == "ts") |>
      dplyr::distinct(concept_name) |>
      dplyr::pull(concept_name)

    if (length(ts_concepts) == 0L) {
      message("No TS concepts found for: ", src_name)
    } else {
      build_ts_table(con, schema_names, ts_concepts,
                     table_name   = ts_table_name,
                     icu_stay_col = icu_stay_col)
      message("TS table built: ", ts_table_name)
    }
  }

  # Build flat table
  if (build_flat) {
    if (is.null(flat_concepts) || length(flat_concepts) == 0L) {
      message("No flat_concepts provided – skipping flat table.")
    } else {
      build_flat_table(con, schema_names, flat_concepts,
                       table_name   = flat_table_name,
                       icu_stay_col = icu_stay_col)
      message("Flat table built: ", flat_table_name)
    }
  }

  # Duration (placeholder)
  if (build_dur) {
    message("Duration table builder not yet implemented.")
  }

  invisible(TRUE)
}
