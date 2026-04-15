# ==============================================================================
# concepts.R — SQL concept builders (unified across MIMIC-III, MIMIC-IV, eICU)
# ==============================================================================

# ---- Unit conversion --------------------------------------------------------

concept_unit_conversion_func <- function(conversion, val_var) {
  v    <- paste0("src.", val_var)
  base <- sprintf("CAST(%s AS NUMERIC)", v)

  if (is.na(conversion) || conversion %in% c("", "none", "unknown_but_needed")) {
    return(base)
  }

  switch(conversion,
    fraction_to_percent = sprintf("%s * 100",       base),
    lb_to_kg            = sprintf("%s * 0.453592",  base),
    oz_to_kg            = sprintf("%s * 0.0283495", base),
    f_to_c              = sprintf("(%s - 32) * 5.0/9.0", base),
    {
      # Generic *N or /N
      if (grepl("^\\*\\s*[0-9.]+$", conversion)) {
        num <- sub("^\\*\\s*", "", conversion)
        return(sprintf("%s * %s", base, num))
      }
      if (grepl("^/\\s*[0-9.]+$", conversion)) {
        num <- sub("^/\\s*", "", conversion)
        return(sprintf("%s / %s", base, num))
      }
      stop("Unknown conversion: ", conversion)
    }
  )
}


# ---- Per-class SELECT builders (unified, parameterized) --------------------

build_select_itemid_tpl <- function(table_name, sub_var, match_value,
                                    val_var, unit_var, index_var,
                                    conversion, raw_schema, dict, unit,
                                    icu_stay_col) {
  conv_sql  <- concept_unit_conversion_func(conversion, val_var)
  dict_join <- if (!is.na(dict) && nzchar(dict)) {
    glue::glue("LEFT JOIN {raw_schema}.{dict} dict\n  ON src.{sub_var} = dict.{sub_var}")
  } else ""
  label_col <- if (!is.na(dict) && nzchar(dict)) "dict.label AS source_label," else "NULL AS source_label,"

  glue::glue("
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.{icu_stay_col},
    adm.admittime,
    src.{index_var},
    EXTRACT(EPOCH FROM (src.{index_var} - adm.admittime))/60 AS offset_min,
    {conv_sql} AS value,
    '{unit}' AS unit,
    src.{val_var} AS value_raw,
    src.{unit_var} AS unit_raw,
    src.{sub_var} AS source_itemid,
    {label_col}
    '{table_name}' AS source_table,
    '{raw_schema}' AS source_dataset
FROM {raw_schema}.visit_windows cw
JOIN {raw_schema}.{table_name} src ON cw.hadm_id = src.hadm_id
JOIN {raw_schema}.admissions    adm ON cw.hadm_id = adm.hadm_id
{dict_join}
WHERE src.{sub_var} IN ({match_value})
  AND src.{val_var} IS NOT NULL
  AND src.{index_var} BETWEEN cw.hospital_start AND cw.hospital_end
")
}


build_select_regex_tpl <- function(table_name, sub_var, match_value,
                                   val_var, unit_var, index_var,
                                   conversion, raw_schema, dict, unit,
                                   icu_stay_col) {
  conv_sql     <- concept_unit_conversion_func(conversion, val_var)
  dict_join    <- if (!is.na(dict) && nzchar(dict)) {
    glue::glue("LEFT JOIN {raw_schema}.{dict} dict\n  ON src.{sub_var} = dict.{sub_var}")
  } else ""
  label_col    <- if (!is.na(dict) && nzchar(dict)) "dict.label AS source_label," else "NULL AS source_label,"
  regex_target <- if (!is.na(dict) && nzchar(dict)) "LOWER(dict.label)" else glue::glue("LOWER(src.{sub_var})")

  glue::glue("
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.{icu_stay_col},
    adm.admittime,
    src.{index_var},
    EXTRACT(EPOCH FROM (src.{index_var} - adm.admittime))/60 AS offset_min,
    {conv_sql} AS value,
    '{unit}' AS unit,
    src.{val_var} AS value_raw,
    src.{unit_var} AS unit_raw,
    src.{sub_var} AS source_itemid,
    {label_col}
    '{table_name}' AS source_table,
    '{raw_schema}' AS source_dataset
FROM {raw_schema}.visit_windows cw
JOIN {raw_schema}.{table_name} src ON cw.hadm_id = src.hadm_id
JOIN {raw_schema}.admissions    adm ON cw.hadm_id = adm.hadm_id
{dict_join}
WHERE {regex_target} ~ '{match_value}'
  AND src.{val_var} IS NOT NULL
  AND src.{index_var} BETWEEN cw.hospital_start AND cw.hospital_end
")
}


build_select_column_tpl <- function(table_name, sub_var,
                                    val_var, unit_var, index_var,
                                    conversion, raw_schema, dict, unit,
                                    icu_stay_col) {
  conv_sql  <- concept_unit_conversion_func(conversion, val_var)
  dict_join <- if (!is.na(dict) && nzchar(dict)) {
    glue::glue("LEFT JOIN {raw_schema}.{dict} dict\n  ON src.{sub_var} = dict.{sub_var}")
  } else ""

  glue::glue("
SELECT
    cw.subject_id,
    cw.hadm_id,
    cw.{icu_stay_col},
    adm.admittime,
    src.{index_var},
    EXTRACT(EPOCH FROM (src.{index_var} - adm.admittime))/60 AS offset_min,
    {conv_sql} AS value,
    '{unit}' AS unit,
    src.{val_var} AS value_raw,
    src.{unit_var} AS unit_raw,
    NULL AS source_itemid,
    NULL AS source_label,
    '{table_name}' AS source_table,
    '{raw_schema}' AS source_dataset
FROM {raw_schema}.visit_windows cw
JOIN {raw_schema}.{table_name} src ON cw.hadm_id = src.hadm_id
JOIN {raw_schema}.admissions    adm ON cw.hadm_id = adm.hadm_id
{dict_join}
WHERE src.{val_var} IS NOT NULL
  AND src.{index_var} BETWEEN cw.hospital_start AND cw.hospital_end
")
}


# ---- Dispatcher -------------------------------------------------------------

build_select_concept <- function(table_name, sub_var, match_value,
                                 val_var, unit_var, index_var,
                                 conversion, raw_schema, dict, unit,
                                 class, icu_stay_col) {
  switch(class,
    itm_itm = build_select_itemid_tpl(table_name, sub_var, match_value,
                                      val_var, unit_var, index_var,
                                      conversion, raw_schema, dict, unit,
                                      icu_stay_col),
    rgx_itm = build_select_regex_tpl(table_name, sub_var, match_value,
                                     val_var, unit_var, index_var,
                                     conversion, raw_schema, dict, unit,
                                     icu_stay_col),
    col_itm = build_select_column_tpl(table_name, sub_var,
                                      val_var, unit_var, index_var,
                                      conversion, raw_schema, dict, unit,
                                      icu_stay_col),
    stop("Unknown concept class: ", class)
  )
}


# ---- Concept SQL assembly ---------------------------------------------------

build_atomic_concept_sql <- function(df, raw_schema, concepts_schema,
                                     icu_stay_col) {
  df_small <- df[, c("table_name", "class", "sub_var", "match_value",
                     "val_var", "unit_var", "index_var", "conversion",
                     "source", "dict", "unit"), drop = FALSE]

  selects <- purrr::pmap_chr(df_small, function(table_name, class, sub_var,
                                                 match_value, val_var, unit_var,
                                                 index_var, conversion,
                                                 source, dict, unit) {
    build_select_concept(
      table_name  = table_name,
      sub_var     = sub_var,
      match_value = match_value,
      val_var     = val_var,
      unit_var    = unit_var,
      index_var   = index_var,
      conversion  = conversion,
      raw_schema  = raw_schema,
      dict        = dict,
      unit        = unit,
      class       = class,
      icu_stay_col = icu_stay_col
    )
  })

  union_sql <- paste(selects, collapse = "\nUNION ALL\n")

  glue::glue("
DROP TABLE IF EXISTS {concepts_schema}.{df$concept_name[1]};
CREATE TABLE {concepts_schema}.{df$concept_name[1]} AS
{union_sql};
")
}


# ---- Pipeline concept runners -----------------------------------------------

#' Build and execute atomic concept tables from a concept config CSV.
#'
#' For each concept defined in the config (filtered by \code{src_name} and
#' optionally \code{typ}), a \code{CREATE TABLE} statement is generated,
#' written to \code{sql_out_dir}, and executed against the database.
#'
#' @param con                 A DBI connection.
#' @param concept_config_path Path to the concept config CSV.
#' @param src_name            Source schema name (the \code{raw} schema,
#'   e.g. \code{"miii_demo_coh"}).
#' @param schema_names        Schema names list from \code{\link{src_schema_names}}.
#' @param typ                 Optional character vector of concept types to run
#'   (e.g. \code{"ts"}).  \code{NULL} runs all types.
#' @param sql_out_dir         Directory where generated SQL files are saved.
#' @param icu_stay_col        ICU stay column name.  Auto-detected if \code{NULL}.
#' @return Invisible character vector of executed concept names.
#' @export
run_atomic_concepts <- function(con, concept_config_path, src_name,
                                schema_names, typ = NULL, sql_out_dir,
                                icu_stay_col = NULL) {
  if (is.null(icu_stay_col)) {
    icu_stay_col <- get_icu_stay_col(src_name)
  }

  concepts <- readr::read_csv(concept_config_path, show_col_types = FALSE)
  concepts <- concepts[concepts$source == src_name, , drop = FALSE]

  if (!is.null(typ)) {
    concepts <- concepts[concepts$typ %in% typ, , drop = FALSE]
  }

  if (nrow(concepts) == 0L) {
    message("No concepts found for source '", src_name, "'.")
    return(invisible(character(0L)))
  }

  grouped <- dplyr::group_split(dplyr::group_by(concepts, concept_name))
  concept_names <- vapply(grouped, function(x) x$concept_name[1L], character(1L))

  sqls <- purrr::map_chr(grouped, build_atomic_concept_sql,
                         raw_schema      = schema_names$raw,
                         concepts_schema = schema_names$concepts,
                         icu_stay_col    = icu_stay_col)

  dir.create(sql_out_dir, recursive = TRUE, showWarnings = FALSE)

  purrr::walk2(sqls, concept_names, function(sql, name) {
    writeLines(sql, file.path(sql_out_dir, paste0(name, ".sql")))
    tryCatch({
      DBI::dbExecute(con, sql, immediate = TRUE)
      message("  OK: ", name)
    }, error = function(e) {
      message("  FAIL: ", name, " | ", e$message)
    })
  })

  invisible(concept_names)
}


#' Execute handcrafted flat and duration SQL files from the package.
#'
#' @param con   A DBI connection.
#' @param paths Paths list from \code{\link{make_project_paths}}.
#' @export
run_handcrafted_concepts <- function(con, paths) {
  run_sql_dir(con, paths$flat_sql_dir)
  run_sql_dir(con, paths$duration_sql_dir)
}
