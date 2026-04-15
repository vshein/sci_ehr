# ==============================================================================
# explore.R — Interactive data exploration helpers
# ==============================================================================

#' Find close matches for a query string within a set of choices.
#'
#' Uses prefix matching, substring matching, and normalized edit distance as
#' fallbacks.
#'
#' @param query         The search string.
#' @param choices       Character vector of candidates.
#' @param max_suggestions Maximum number of suggestions to return.
#' @return Character vector of suggested matches.
#' @export
suggest_match <- function(query, choices, max_suggestions = 3L) {
  if (length(choices) == 0L) return(character(0L))

  q <- tolower(query)
  cl <- tolower(choices)

  # 1. Prefix match
  pm <- choices[startsWith(cl, q)]
  if (length(pm) > 0L) return(head(pm, max_suggestions))

  # 2. Substring match
  sm <- choices[grepl(q, cl, fixed = TRUE)]
  if (length(sm) > 0L) return(head(sm, max_suggestions))

  # 3. Normalized edit distance
  dists      <- utils::adist(q, cl)
  norm_dists <- dists / pmax(nchar(cl), 1L)
  ord        <- order(norm_dists)
  keep       <- norm_dists[ord] <= 0.4
  if (!any(keep)) return(character(0L))
  head(choices[ord][keep], max_suggestions)
}


format_choices <- function(x, max_show = 12L, ncol = 3L) {
  if (length(x) == 0L) return("  (none)")
  x     <- sort(x)
  extra <- length(x) - max_show
  x_show <- head(x, max_show)
  splits <- split(x_show, ceiling(seq_along(x_show) / ceiling(max_show / ncol)))
  lines  <- do.call(paste, c(splits, sep = "   "))
  out    <- paste0("  ", lines, collapse = "\n")
  if (extra > 0L) out <- paste0(out, sprintf("\n  ... and %d more", extra))
  out
}


#' Fetch a table from PostgreSQL as a data frame (dplyr-style).
#'
#' @param con    A DBI connection.
#' @param schema Schema name.
#' @param table  Table name.
#' @param n      Maximum rows to collect (\code{Inf} for all).
#' @return A data frame, or \code{NULL} on error with a diagnostic message.
#' @export
get_table_from_db <- function(con, schema, table, n = Inf) {
  stopifnot(DBI::dbIsValid(con))
  tbl_id <- DBI::Id(schema = schema, table = table)
  tbl    <- dplyr::tbl(con, tbl_id)
  if (is.finite(n)) dplyr::collect(tbl, n = n) else dplyr::collect(tbl)
}


#' Fetch a table from PostgreSQL as a \code{data.table} with smart error messages.
#'
#' If the schema or table does not exist, prints a diagnostic message with
#' spelling suggestions and a list of available schemas / tables.
#'
#' @param con    A DBI connection.
#' @param schema Schema name.
#' @param table  Table name.
#' @param n      Maximum rows (\code{Inf} for all).
#' @return A \code{data.table}, or \code{NULL} on error.
#' @export
get_dt_from_db <- function(con, schema, table, n = Inf) {
  stopifnot(DBI::dbIsValid(con))
  stopifnot(is.character(schema), length(schema) == 1L)
  stopifnot(is.character(table),  length(table)  == 1L)

  schema_q <- DBI::dbQuoteIdentifier(con, schema)
  table_q  <- DBI::dbQuoteIdentifier(con, table)
  query    <- paste0("SELECT * FROM ", schema_q, ".", table_q)
  if (is.finite(n)) query <- paste0(query, " LIMIT ", as.integer(n))

  tryCatch(
    data.table::as.data.table(DBI::dbGetQuery(con, query)),
    error = function(e) {
      message(sprintf("Could not query '%s.%s'.", schema, table))

      schemas      <- DBI::dbGetQuery(con,
        "SELECT schema_name FROM information_schema.schemata"
      )$schema_name
      schemas_user <- schemas[!schemas %in% c("information_schema", "pg_catalog")]

      if (!schema %in% schemas) {
        message("\nSchema not found.")
        sug <- suggest_match(schema, schemas_user)
        if (length(sug) > 0L) message("Did you mean:\n",
                                       paste("  ->", sug, collapse = "\n"))
        message("\nAvailable schemas:\n", format_choices(schemas_user))
        return(invisible(NULL))
      }

      tables <- DBI::dbGetQuery(con,
        sprintf("SELECT table_name FROM information_schema.tables
                  WHERE table_schema = %s",
                DBI::dbQuoteString(con, schema))
      )$table_name

      if (!table %in% tables) {
        message("\nTable not found.")
        sug <- suggest_match(table, tables)
        if (length(sug) > 0L) message("Did you mean:\n",
                                       paste("  ->", sug, collapse = "\n"))
        message(sprintf("\nAvailable tables in '%s':\n", schema),
                format_choices(tables))
        return(invisible(NULL))
      }

      message("\nSchema and table exist but the query failed.\nError: ", e$message)
      invisible(NULL)
    }
  )
}
