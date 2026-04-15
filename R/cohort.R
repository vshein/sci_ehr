# ==============================================================================
# cohort.R — Cohort identification and subsetting
# ==============================================================================

#' Return the ICU-stay column name for a given source.
#'
#' @param src_name Source identifier.
#' @return A column name string.
get_icu_stay_col <- function(src_name) {
  if (grepl("miii", src_name, ignore.case = TRUE)) return("icustay_id")
  if (grepl("eicu", src_name, ignore.case = TRUE)) return("patientunitstayid")
  "stay_id"  # miiv and future sources
}


#' Return the ICD code column name for a given source.
#'
#' @param src_name Source identifier.
#' @return A column name string.
get_icd_col <- function(src_name) {
  if (grepl("miii", src_name, ignore.case = TRUE)) return("icd9_code")
  "icd_code"  # miiv and others use icd_code
}


#' Generate cohort subject IDs by filtering on SCI-related ICD codes.
#'
#' Reads the diagnoses FST file and the ICD code list, then returns distinct
#' \code{subject_id}s that appear in the cohort.
#'
#' @param diag_path      Path to the \code{diagnoses_icd.fst} file.
#' @param icds_scid_path Path to a CSV with a column \code{icd_code}.
#' @param icd_col        Column name in the diagnosis table that holds ICD
#'   codes.  Auto-detected from \code{src_name} if supplied.
#' @return A one-column data frame with \code{subject_id}.
#' @export
gen_cohort_ids <- function(diag_path, icds_scid_path,
                           icd_col = "icd_code") {
  diag     <- fst::read_fst(diag_path)
  icds_sci <- readr::read_csv(icds_scid_path, show_col_types = FALSE)

  cohort_codes <- as.character(icds_sci$icd_code)

  diag$icd_code_std <- as.character(diag[[icd_col]])

  coh <- diag[diag$icd_code_std %in% cohort_codes, , drop = FALSE]
  unique(coh[, "subject_id", drop = FALSE])
}


#' Build cohort IDs from the diagnoses FST file for a given source.
#'
#' @param paths          Paths list from \code{\link{make_project_paths}}.
#' @param icds_scid_path Path to the SCI ICD code list CSV.
#' @param src_name       Source identifier (used to determine ICD column).
#' @return A one-column data frame with \code{subject_id}.
#' @export
build_cohort_ids <- function(paths, icds_scid_path, src_name = "") {
  diag_path <- file.path(paths$raw_dir, "diagnoses_icd.fst")
  icd_col   <- get_icd_col(src_name)
  gen_cohort_ids(diag_path, icds_scid_path, icd_col = icd_col)
}


#' Subset all raw FST files to a cohort.
#'
#' Wraps \code{\link{subset_fst_by_key}} using the standard
#' \code{subject_id} key.
#'
#' @param paths      Paths list from \code{\link{make_project_paths}}.
#' @param cohort_ids Data frame with a \code{subject_id} column.
#' @param key        Join key column name.
#' @export
subset_source_to_cohort <- function(paths, cohort_ids, key = "subject_id") {
  key_values        <- list()
  key_values[[key]] <- unique(cohort_ids[[key]])
  subset_fst_by_key(
    input_path  = paths$raw_dir,
    output_path = paths$cohort_fst_dir,
    key         = key,
    key_values  = key_values
  )
}


#' Write SCI ICD and injury ICD lookup tables into the raw schema.
#'
#' Also runs the \code{visit_windows.sql} helper script.
#'
#' @param con            A DBI connection.
#' @param paths          Paths list from \code{\link{make_project_paths}}.
#' @param schema_names   Schema names list from \code{\link{src_schema_names}}.
#' @param icds_scid_path Path to the SCI ICD code CSV.
#' @param icds_inj_path  Path to the injury ICD code CSV.
#' @export
add_scid_tables <- function(con, paths, schema_names,
                            icds_scid_path, icds_inj_path) {
  d_scid_icd <- utils::read.csv(icds_scid_path)
  d_inj_icd  <- utils::read.csv(icds_inj_path)

  write_lookup_table(con, schema_names$raw, "d_scid_icd", d_scid_icd)
  write_lookup_table(con, schema_names$raw, "d_inj_icd",  d_inj_icd)

  create_index(con, schema_names$raw, "d_scid_icd", "idx_d_scid_icd_code", "icd_code")
  create_index(con, schema_names$raw, "d_inj_icd",  "idx_d_inj_icd_code",  "icd_code")

  vw_sql <- file.path(paths$helper_sql_dir, "visit_windows.sql")
  if (file.exists(vw_sql)) {
    run_sql_file(con, vw_sql)
  } else {
    warning("visit_windows.sql not found at: ", vw_sql, call. = FALSE)
  }
  invisible(NULL)
}
