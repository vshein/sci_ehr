# ==============================================================================
# import.R — CSV → FST ingestion and FST → PostgreSQL loading
# ==============================================================================

# ---- S3 generics for tbl_cfg objects ----------------------------------------

col_spec      <- function(x, ...) UseMethod("col_spec")
partition_fun <- function(x, ...) UseMethod("partition_fun")
partition_col <- function(x, ...) UseMethod("partition_col")
raw_file_name <- function(x, ...) UseMethod("raw_file_name")
fst_file_name <- function(x, ...) UseMethod("fst_file_name")
tbl_name      <- function(x, ...) UseMethod("tbl_name")
n_row         <- function(x, ...) UseMethod("n_row")
n_part        <- function(x, ...) UseMethod("n_part")
ricu_cols     <- function(x, ...) UseMethod("ricu_cols")
orig_cols     <- function(x, ...) UseMethod("orig_cols")

col_spec.tbl_cfg      <- function(x, ...) x$col_spec_obj
partition_fun.tbl_cfg <- function(x, ...) x$part_fun
partition_col.tbl_cfg <- function(x, ...) x$part_col
raw_file_name.tbl_cfg <- function(x, ...) x$csv_file
tbl_name.tbl_cfg      <- function(x, ...) x$table_name
n_row.tbl_cfg         <- function(x, ...) x$expected_rows
n_part.tbl_cfg        <- function(x, ...) x$n_parts
ricu_cols.tbl_cfg     <- function(x, ...) x$ricu_names
orig_cols.tbl_cfg     <- function(x, ...) x$orig_names

fst_file_name.tbl_cfg <- function(x, ...) {
  if (x$has_partition) {
    file.path(x$table_name, paste0(seq_len(x$n_parts), ".fst"))
  } else {
    paste0(x$table_name, ".fst")
  }
}


# ---- Config parsing ---------------------------------------------------------

build_readr_cols <- function(cols_json) {
  spec_list <- list()
  for (nm in names(cols_json)) {
    cd <- cols_json[[nm]]
    orig <- cd$name
    spec_list[[orig]] <- switch(
      cd$spec,
      col_integer   = readr::col_integer(),
      col_double    = readr::col_double(),
      col_number    = readr::col_number(),
      col_character = readr::col_character(),
      col_logical   = readr::col_logical(),
      col_datetime  = if (!is.null(cd$format)) readr::col_datetime(cd$format)
                      else readr::col_datetime(),
      col_date      = if (!is.null(cd$format)) readr::col_date(cd$format)
                      else readr::col_date(),
      col_time      = readr::col_time(),
      col_skip      = readr::col_skip(),
      readr::col_guess()
    )
  }
  do.call(readr::cols, spec_list)
}


parse_tbl_cfg <- function(table_name, tbl_json) {
  ricu_nms <- names(tbl_json$cols)
  orig_nms <- vapply(tbl_json$cols, function(cd) cd$name, character(1L))
  spec     <- build_readr_cols(tbl_json$cols)

  has_part <- !is.null(tbl_json$partitioning)
  if (has_part) {
    part_col_orig <- tbl_json$partitioning$col
    breaks        <- sort(unlist(tbl_json$partitioning$breaks))
    n_parts       <- length(breaks) + 1L
    pfun <- function(df) findInterval(df[[part_col_orig]], breaks) + 1L
  } else {
    part_col_orig <- NULL; breaks <- NULL; n_parts <- 1L; pfun <- NULL
  }

  structure(
    list(table_name    = table_name,
         csv_file      = tbl_json$files,
         expected_rows = if (!is.null(tbl_json$num_rows)) tbl_json$num_rows
                         else NA_real_,
         col_spec_obj  = spec,
         ricu_names    = ricu_nms,
         orig_names    = unname(orig_nms),
         has_partition = has_part,
         part_col      = part_col_orig,
         part_breaks   = breaks,
         n_parts       = n_parts,
         part_fun      = pfun),
    class = "tbl_cfg"
  )
}


# ---- Chunked write helpers --------------------------------------------------

split_write <- function(x, part_fun, dir, chunk_no, prog, nme, tick) {
  n_row_x <- nrow(x)
  x       <- split(x, part_fun(x))
  tmp_nme <- file.path(dir, paste0("part_", names(x)),
                       paste0("chunk_", chunk_no, ".fst"))
  ensure_dirs(unique(dirname(tmp_nme)))
  Map(fst::write_fst, x, tmp_nme)
  progress_tick(paste(nme, "chunk", chunk_no), prog,
                .coalesce(tick, floor(n_row_x / 2)))
  invisible(NULL)
}

merge_fst_chunks <- function(src, targ, new, old, sort_col, prog, nme, tick) {
  files <- list.files(src, full.names = TRUE)
  if (length(files) == 0L) return(invisible(NULL))
  sort_ind <- order(
    as.integer(sub("^chunk_", "", sub("\\.fst$", "", basename(files))))
  )
  dat <- lapply(files[sort_ind], fst::read_fst, as.data.table = TRUE)
  dat <- data.table::rbindlist(dat)
  data.table::setorderv(dat, sort_col)
  if (!is.null(new) && !is.null(old)) {
    rename_cols(dat, new, old, skip_absent = TRUE, by_ref = TRUE)
  }
  part_no  <- sub("part_", "", basename(src))
  new_file <- file.path(ensure_dirs(targ), paste0(part_no, ".fst"))
  fst::write_fst(dat, new_file, compress = 100L)
  progress_tick(paste(nme, "part", part_no), prog,
                .coalesce(tick, floor(nrow(dat) / 2)))
  invisible(NULL)
}


# ---- CSV → FST --------------------------------------------------------------

gunzip_file <- function(file, exdir) {
  dest <- file.path(exdir, sub("\\.gz$", "", basename(file)))
  if (file.exists(dest)) return(dest)
  inp <- gzfile(file, open = "rb")
  on.exit(close(inp))
  out <- file(dest, open = "wb")
  on.exit(close(out), add = TRUE)
  repeat {
    tmp <- readBin(inp, what = raw(0L), size = 1L, n = 1e7)
    if (length(tmp) == 0L) break
    writeBin(tmp, con = out, size = 1L)
  }
  dest
}


partition_table <- function(x, dir, progress = NULL, chunk_length = 10^7, ...) {
  tempdir_path <- ensure_dirs(tempfile())
  on.exit(unlink(tempdir_path, recursive = TRUE))

  spec  <- col_spec(x); pfun <- partition_fun(x); rawf <- raw_file_name(x)
  file  <- file.path(dir, rawf); name <- tbl_name(x); exp_row <- n_row(x)

  tick <- if (is.na(exp_row)) { if (length(file) == 1L) 0L else 1L } else NULL

  if (length(file) == 1L) {
    callback <- function(chunk, pos) {
      report_problems(chunk, rawf)
      data.table::setDT(chunk)
      split_write(chunk, pfun, tempdir_path,
                  ((pos - 1L) / chunk_length) + 1L, progress, name, tick)
    }
    read_file <- file
    if (grepl("\\.gz$", file)) read_file <- gunzip_file(file, tempdir_path)
    readr::read_csv_chunked(read_file,
                             readr::SideEffectChunkCallback$new(callback),
                             chunk_size = chunk_length,
                             col_types  = spec,
                             progress   = FALSE, ...)
    if (is.na(exp_row)) progress_tick(NULL, progress)
  } else {
    for (i in seq_along(file)) {
      dat <- readr::read_csv(file[i], col_types = spec, progress = FALSE, ...)
      report_problems(dat, rawf[i])
      data.table::setDT(dat)
      split_write(dat, pfun, tempdir_path, i, progress, name, tick)
    }
  }

  targ <- file.path(dir, name)
  newc <- ricu_cols(x); oldc <- orig_cols(x)
  if (is.na(exp_row)) tick <- 1L

  for (p in seq_len(n_part(x))) {
    src_dir <- file.path(tempdir_path, paste0("part_", p))
    if (dir.exists(src_dir)) {
      merge_fst_chunks(src_dir, targ, newc, oldc,
                       partition_col(x), progress, name, tick)
    }
  }

  if (!is.null(tick)) {
    fst_files <- file.path(dir, fst_file_name(x))
    act_row   <- sum(dbl_ply(lapply(fst_files, fst::fst), nrow))
    if (act_row != exp_row) {
      warn_ricu(paste0("Expected ", exp_row, " rows but got ", act_row,
                       " for table `", name, "`"))
    }
  }
  invisible(NULL)
}


csv_to_fst <- function(x, dir, progress = NULL, ...) {
  raw <- raw_file_name(x)
  src <- file.path(dir, raw)
  dst <- file.path(dir, fst_file_name(x))

  dat <- suppressWarnings(
    readr::read_csv(src, col_types = col_spec(x), progress = FALSE, ...)
  )
  report_problems(dat, raw)
  data.table::setDT(dat)

  newc <- ricu_cols(x); oldc <- orig_cols(x)
  if (!is.null(newc) && !is.null(oldc)) {
    rename_cols(dat, newc, oldc, skip_absent = TRUE, by_ref = TRUE)
  }

  fst::write_fst(dat, dst, compress = 100L)

  exp_row <- n_row(x); tbl <- tbl_name(x)
  if (!is.na(exp_row)) {
    act_row <- nrow(fst::fst(dst))
    if (act_row != exp_row) {
      warn_ricu(paste0("Expected ", exp_row, " rows but got ", act_row,
                       " for table `", tbl, "`"))
    }
  }

  progress_tick(tbl, progress, if (is.na(exp_row)) 1L else exp_row)
  invisible(NULL)
}


import_table <- function(table_name, tbl_json, data_dir, chunk_length = 10^7) {
  cfg <- parse_tbl_cfg(table_name, tbl_json)
  message("  Import: ", table_name, "  [", cfg$csv_file, "]")
  if (cfg$has_partition) {
    partition_table(cfg, data_dir, chunk_length = chunk_length)
  } else {
    csv_to_fst(cfg, data_dir)
  }
  message("  Done:   ", table_name)
}


#' Import raw CSV files to FST format.
#'
#' @param src_name     Source name.
#' @param tables       Character vector of table names to import.
#' @param data_dir     Directory containing the downloaded CSV files.
#' @param config_path  Path to the data-sources JSON.
#' @param chunk_length Rows per chunk for large tables.
#' @export
import_data <- function(src_name, tables, data_dir,
                        config_path = system.file("config", "data-sources.json",
                                                  package = "sciehr"),
                        chunk_length = 10^7) {
  src_cfg     <- load_src_config(config_path, src_name)
  tables_json <- src_cfg$tables

  missing <- setdiff(tables, names(tables_json))
  if (length(missing) > 0L) {
    stop("Tables not in config: ", paste(missing, collapse = ", "))
  }

  message("\n*** Importing CSV → FST: ", src_name, " ***\n")
  for (tbl in tables) {
    import_table(tbl, tables_json[[tbl]], data_dir, chunk_length = chunk_length)
  }
  message("FST files saved to: ", data_dir)
  invisible(TRUE)
}


#' Subset FST files to a cohort defined by key values.
#'
#' Each \code{.fst} file in \code{input_path} is read and filtered so that
#' only rows matching \code{key_values} are kept.  Files that do not contain
#' the key column are copied unchanged (e.g. dictionary tables).
#'
#' @param input_path  Directory containing the raw FST files.
#' @param output_path Directory where cohort-subset FST files are written.
#' @param key         Column name used for subsetting (e.g. \code{"subject_id"}).
#' @param key_values  Named list where the element named \code{key} contains
#'   the set of accepted values.
#' @param overwrite   Overwrite existing output files?
#' @export
subset_fst_by_key <- function(input_path, output_path, key, key_values,
                              overwrite = FALSE) {
  if (!dir.exists(output_path)) dir.create(output_path, recursive = TRUE)

  fst_files <- list.files(input_path, pattern = "\\.fst$",
                          full.names = TRUE, recursive = TRUE)
  if (length(fst_files) == 0L) stop("No .fst files found in: ", input_path)

  message("Subsetting ", length(fst_files), " FST file(s) by '", key, "'...")

  for (file in fst_files) {
    message("  Processing: ", basename(file))
    df <- fst::read_fst(file)

    df_subset <- if (!key %in% names(df)) {
      warning("Key '", key, "' not in ", basename(file),
              " – copying without filter.", call. = FALSE)
      df
    } else if (!key %in% names(key_values)) {
      stop("Key '", key, "' not found in key_values list.")
    } else {
      df[df[[key]] %in% key_values[[key]], , drop = FALSE]
    }

    rel_path <- sub(paste0("^", gsub("\\\\", "/", input_path), "/?"), "",
                    gsub("\\\\", "/", file))
    out_file <- file.path(output_path, rel_path)
    dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

    if (file.exists(out_file) && !overwrite) {
      warning("File exists, skipping: ", out_file, call. = FALSE)
      next
    }
    fst::write_fst(df_subset, out_file, compress = 100L)
    message("  Saved: ", out_file)
  }
  invisible(TRUE)
}


#' Load FST files from a directory into PostgreSQL tables.
#'
#' Partitioned tables (directories containing multiple \code{.fst} chunks) are
#' merged automatically.
#'
#' @param fst_dir       Directory containing \code{.fst} files.
#' @param con           A DBI connection.
#' @param schema        Target PostgreSQL schema.
#' @param overwrite     Drop existing tables before loading?
#' @param show_progress Show a progress bar?
#' @export
convert_fst_to_psql <- function(fst_dir, con, schema, overwrite = FALSE,
                                show_progress = TRUE) {
  if (!dir.exists(fst_dir))    stop("fst_dir does not exist: ", fst_dir)
  if (!DBI::dbIsValid(con))    stop("Invalid database connection.")

  fst_files <- list.files(fst_dir, pattern = "\\.fst$",
                          full.names = TRUE, recursive = TRUE)
  if (length(fst_files) == 0L) stop("No .fst files found in: ", fst_dir)

  is_root    <- dirname(fst_files) == fst_dir
  dir_counts <- table(dirname(fst_files))

  table_keys <- vapply(seq_along(fst_files), function(i) {
    f <- fst_files[i]; d <- dirname(f)
    if (!is_root[i] && dir_counts[[d]] > 1) basename(d)
    else tools::file_path_sans_ext(basename(f))
  }, character(1L))

  groups <- split(fst_files, table_keys)

  sanitize_name <- function(nm) {
    nm <- tolower(gsub("[^A-Za-z0-9_]", "_", nm))
    if (grepl("^[0-9]", nm)) nm <- paste0("t_", nm)
    nm
  }

  if (show_progress && requireNamespace("progress", quietly = TRUE)) {
    pb <- progress::progress_bar$new(
      format = "  [:bar] :percent | :current/:total | :table | :file",
      total  = length(fst_files), clear = FALSE, width = 80
    )
  } else {
    pb <- NULL
  }

  DBI::dbWithTransaction(con, {
    for (grp in names(groups)) {
      table_name <- sanitize_name(grp)
      files      <- sort(groups[[grp]])
      message("Loading table: ", table_name)

      tbl_id <- DBI::Id(schema = schema, table = table_name)
      if (DBI::dbExistsTable(con, tbl_id)) {
        if (!overwrite) stop("Table exists: ", table_name,
                             ". Use overwrite = TRUE.")
        DBI::dbRemoveTable(con, tbl_id)
      }

      first_chunk <- TRUE
      for (file in files) {
        df   <- fst::read_fst(file, as.data.table = FALSE)
        df[] <- lapply(df, function(x) if (is.factor(x)) as.character(x) else x)
        DBI::dbWriteTable(con, tbl_id, df,
                          append    = !first_chunk,
                          row.names = FALSE)
        first_chunk <- FALSE
        if (!is.null(pb)) pb$tick(tokens = list(table = table_name,
                                                 file  = basename(file)))
      }
      message("  Done: ", table_name)
    }
  })
  invisible(TRUE)
}
