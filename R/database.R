# ==============================================================================
# database.R — PostgreSQL connection and schema management
# ==============================================================================

#' Open a connection to a PostgreSQL database.
#'
#' @param db_name  Database name.
#' @param creds    Credentials list from \code{\link{load_credentials}}.
#' @param host     Host name.  Default \code{"localhost"}.
#' @param port     Port number.  Default \code{5432}.
#' @return A \code{DBIConnection} object.
#' @export
connect_postgres <- function(db_name, creds, host = "localhost", port = 5432) {
  DBI::dbConnect(
    RPostgres::Postgres(),
    dbname   = db_name,
    host     = host,
    port     = port,
    user     = "postgres",
    password = creds$postgres$password,
    sslmode  = "disable"
  )
}


#' Create a database if it does not already exist.
#'
#' Connects to the \code{postgres} system database as admin to issue
#' \code{CREATE DATABASE}.
#'
#' @inheritParams connect_postgres
#' @export
ensure_database_exists <- function(db_name, creds, host = "localhost",
                                   port = 5432) {
  admin_con <- DBI::dbConnect(
    RPostgres::Postgres(),
    dbname   = "postgres",
    host     = host,
    port     = port,
    user     = "postgres",
    password = creds$postgres$password
  )
  on.exit(DBI::dbDisconnect(admin_con), add = TRUE)

  exists <- DBI::dbGetQuery(
    admin_con,
    sprintf("SELECT 1 FROM pg_database WHERE datname = '%s';", db_name)
  )
  if (nrow(exists) == 0L) {
    DBI::dbExecute(admin_con, sprintf("CREATE DATABASE %s;", db_name))
    message("Created database: ", db_name)
  } else {
    message("Database already exists: ", db_name)
  }
  invisible(NULL)
}


#' Create one or more PostgreSQL schemas if they do not exist.
#'
#' @param con          A DBI connection.
#' @param schema_names A character vector or named list of schema names.
#' @export
create_schemas <- function(con, schema_names) {
  for (s in unlist(schema_names)) {
    DBI::dbExecute(con, sprintf("CREATE SCHEMA IF NOT EXISTS %s;", s))
  }
  invisible(NULL)
}


#' Create a PostgreSQL index if it does not already exist.
#'
#' @param con        A DBI connection.
#' @param schema     Schema name.
#' @param table      Table name.
#' @param index_name Index name.
#' @param columns    Character vector of column names.
#' @export
create_index <- function(con, schema, table, index_name, columns) {
  sql <- sprintf(
    "CREATE INDEX IF NOT EXISTS %s ON %s.%s (%s);",
    index_name, schema, table, paste(columns, collapse = ", ")
  )
  DBI::dbExecute(con, sql)
  invisible(NULL)
}


#' Write a data frame as a lookup table in PostgreSQL.
#'
#' @param con        A DBI connection.
#' @param schema     Target schema.
#' @param table_name Target table name.
#' @param df         Data frame to write.
#' @param overwrite  Drop and recreate the table if it exists.
#' @export
write_lookup_table <- function(con, schema, table_name, df, overwrite = TRUE) {
  full_name <- DBI::Id(schema = schema, table = table_name)
  if (overwrite) DBI::dbRemoveTable(con, full_name, fail_if_missing = FALSE)
  DBI::dbWriteTable(con, full_name, df, append = FALSE)
  invisible(NULL)
}


#' Execute all SQL statements from a file.
#'
#' @param con  A DBI connection.
#' @param path Path to the \code{.sql} file.
#' @export
run_sql_file <- function(con, path) {
  sql <- paste(readLines(path, warn = FALSE), collapse = "\n")
  DBI::dbExecute(con, sql, immediate = TRUE)
  invisible(NULL)
}


#' Execute every \code{.sql} file in a directory (sorted alphabetically).
#'
#' @param con      A DBI connection.
#' @param dir_path Directory containing \code{.sql} files.
#' @export
run_sql_dir <- function(con, dir_path) {
  if (!dir.exists(dir_path)) {
    message("Directory not found, skipping: ", dir_path)
    return(invisible(NULL))
  }
  files <- sort(list.files(dir_path, pattern = "\\.sql$", full.names = TRUE))
  if (length(files) == 0L) {
    message("No .sql files in: ", dir_path)
    return(invisible(NULL))
  }
  for (f in files) run_sql_file(con, f)
  invisible(NULL)
}


#' Return the standard set of PostgreSQL schema names for a source.
#'
#' @param src_name Source identifier, e.g. \code{"miii_demo"}.
#' @return A named list with keys \code{raw}, \code{concepts}, \code{ts},
#'   \code{flat}, and \code{dur}.
#' @export
src_schema_names <- function(src_name) {
  list(
    raw      = paste0(src_name, "_coh"),
    concepts = paste0(src_name, "_coh_concepts"),
    ts       = paste0(src_name, "_coh_ts"),
    flat     = paste0(src_name, "_coh_flat"),
    dur      = paste0(src_name, "_coh_dur")
  )
}
