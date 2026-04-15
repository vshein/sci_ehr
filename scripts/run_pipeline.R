# ==============================================================================
# run_pipeline.R — Example usage of the sciehrpsql package
#
# Load the package with:
#   devtools::load_all()        # during development
#   library(sciehrpsql)         # after installation
# ==============================================================================

# ---- MIMIC-III ---------------------------------------------------------------

run_source_pipeline(
  src_name       = "miii_demo",
  db_name        = "sciehrdov",
  base_dir       = ".",
  icds_scid_path = file.path("config", "icds_ethi_new_07062025.csv"),
  icds_inj_path  = file.path("config", "icds_injury_reason_initial_05032025.csv")
)

run_harmonized_tables(
  src_name      = "miii_demo",
  db_name       = "sciehrdov",
  base_dir      = ".",
  flat_concepts = c("sex", "race", "insurance"),
  build_ts      = TRUE,
  build_flat    = TRUE
)


# ---- MIMIC-IV ----------------------------------------------------------------

run_source_pipeline(
  src_name       = "miiv_demo",
  db_name        = "sciehrdov",
  base_dir       = ".",
  icds_scid_path = file.path("config", "icds_ethi_new_07062025.csv"),
  icds_inj_path  = file.path("config", "icds_injury_reason_initial_05032025.csv")
)

run_harmonized_tables(
  src_name      = "miiv_demo",
  db_name       = "sciehrdov",
  base_dir      = ".",
  flat_concepts = c("sex", "race", "insurance"),
  build_ts      = TRUE,
  build_flat    = TRUE
)


# ---- Merge sources into a single harmonized table ----------------------------

con <- connect_postgres(
  db_name = "sciehrdov",
  creds   = load_credentials(file.path("config", "config_pass.json"))
)

DBI::dbExecute(con, "CREATE SCHEMA IF NOT EXISTS sciehr;")

merge_source_tables(
  con               = con,
  source_schemas    = c("miii_demo_coh_ts", "miiv_demo_coh_ts"),
  table_name        = "ts_tab",
  target_schema     = "sciehr",
  target_table_name = "ts"
)

DBI::dbDisconnect(con)


# ---- Explore data ------------------------------------------------------------

con <- connect_postgres(
  db_name = "sciehrdov",
  creds   = load_credentials(file.path("config", "config_pass.json"))
)

# Browse with smart error messages and spell-check suggestions
get_dt_from_db(con, schema = "miii_demo_coh_ts", table = "ts_tab", n = 100)
get_dt_from_db(con, schema = "miiv_demo_coh_flat", table = "flat_tab", n = 100)

DBI::dbDisconnect(con)
