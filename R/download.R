# ==============================================================================
# download.R — PhysioNet data download helpers
# ==============================================================================

download_file <- function(url, handle = curl::new_handle(), dest = NULL,
                          progr = NULL) {
  if (is.null(dest)) return(curl::curl_fetch_memory(url, handle))
  if (is.null(progr)) return(curl::curl_fetch_disk(url, dest, handle = handle))
  con <- file(dest, "ab", blocking = FALSE)
  on.exit(close(con))
  prog_fun <- function(x) {
    progress_tick(NULL, progr, length(x))
    writeBin(x, con)
  }
  curl::curl_fetch_stream(url, prog_fun, handle = handle)
}


download_physionet_file <- function(url, dest = NULL, user = NULL,
                                    pass = NULL, head_only = FALSE,
                                    progress = NULL) {
  handle <- curl::new_handle(useragent = "Wget/")

  if (!is.null(user) && !is.null(pass)) {
    curl::handle_setopt(handle, username = user, password = pass)
  }

  if (is.null(dest) && head_only) {
    curl::handle_setopt(handle, nobody = TRUE)
  } else if (not_null(dest) && file.exists(dest)) {
    curl::handle_setopt(handle,
                        timevalue     = file.mtime(dest),
                        timecondition = TRUE)
  }

  res    <- download_file(url, handle, dest, progress)
  status <- res[["status_code"]]

  if (status == 304L) {
    msg_ricu(paste0("Skipped (up to date): ", basename(url)))
    return(invisible(NULL))
  } else if (status %in% c(401L, 403L)) {
    stop_ricu("Access denied. Check your PhysioNet credentials.")
  } else if (status != 200L) {
    stop_ricu(paste0("HTTP ", status, " for ", url))
  }

  if (head_only) res
  else if (is.null(dest)) res[["content"]]
  else invisible(NULL)
}


get_sha256 <- function(url, user = NULL, pass = NULL) {
  res <- download_physionet_file(
    paste(url, "SHA256SUMS.txt", sep = "/"),
    dest = NULL, user = user, pass = pass
  )
  con <- rawConnection(res)
  on.exit(close(con))
  strsplit(readLines(con), " ")
}


check_file_sha256 <- function(file, val) {
  if (!requireNamespace("openssl", quietly = TRUE)) {
    warning("Package 'openssl' required for checksum verification.", call. = FALSE)
    return(TRUE)
  }
  isTRUE(as.character(openssl::sha256(file(file, raw = TRUE))) == val)
}


download_check_data <- function(dest_folder, files, url, src,
                                user = NULL, pass = NULL, verbose = TRUE,
                                ...) {
  format_bytes <- function(b) {
    if (is.na(b) || b <= 0) return("???")
    if (b >= 1e9) return(sprintf("%.1f GB", b / 1e9))
    if (b >= 1e6) return(sprintf("%.1f MB", b / 1e6))
    if (b >= 1e3) return(sprintf("%.1f KB", b / 1e3))
    paste0(b, " B")
  }

  get_size <- function(file_url) {
    tryCatch({
      resp   <- download_physionet_file(file_url, NULL, user, pass, head_only = TRUE)
      hdrs   <- parse_headers(resp$headers)
      starts <- grep("^HTTP/", hdrs)
      blk    <- if (length(starts) > 0) hdrs[seq(starts[length(starts)], length(hdrs))] else hdrs
      cl     <- grep("^Content-Length:", blk, ignore.case = TRUE, value = TRUE)
      if (length(cl) >= 1L) {
        v <- as.numeric(sub("^Content-Length:\\s*", "", cl[1L], ignore.case = TRUE))
        if (!is.na(v) && v > 0) return(v)
      }
      NA_real_
    }, error = function(e) NA_real_)
  }

  dl_one <- function(file_url, total_size, path) {
    fname      <- basename(file_url)
    message("  ", fname, "  [", format_bytes(total_size), "]")
    h          <- curl::new_handle(useragent = "Wget/")
    if (!is.null(user) && !is.null(pass)) {
      curl::handle_setopt(h, username = user, password = pass)
    }
    out_con    <- file(path, "wb")
    downloaded <- 0L
    last_print <- 0
    t_start    <- Sys.time()

    prog_fun <- function(x) {
      writeBin(x, out_con)
      downloaded <<- downloaded + length(x)
      now <- as.numeric(Sys.time())
      if ((now - last_print) < 0.5) return(invisible(NULL))
      last_print <<- now
      elapsed <- now - as.numeric(t_start)
      speed   <- if (elapsed > 0.3) downloaded / elapsed else 0
      spd     <- if (speed > 0) paste0(format_bytes(speed), "/s") else ""
      if (!is.na(total_size) && total_size > 0) {
        pct <- min(floor(downloaded / total_size * 100), 100)
        cat(sprintf("\r    [%-50s] %3.0f%%  %s / %s  %s   ",
                    paste(rep("#", max(pct %/% 2, 0)), collapse = ""),
                    pct, format_bytes(downloaded), format_bytes(total_size), spd))
      } else {
        cat(sprintf("\r    %s  %s   ", format_bytes(downloaded), spd))
      }
      flush.console()
    }

    res <- curl::curl_fetch_stream(file_url, prog_fun, handle = h)
    close(out_con)

    elapsed <- as.numeric(difftime(Sys.time(), t_start, units = "secs"))
    speed   <- if (elapsed > 0) downloaded / elapsed else 0
    cat(sprintf("\r    [%-50s] 100%%  %s  %s/s  done\n",
                paste(rep("#", 50), collapse = ""),
                format_bytes(downloaded), format_bytes(speed)))

    status <- res[["status_code"]]
    if (status %in% c(401L, 403L)) stop_ricu("Access denied.")
    else if (status != 200L) stop_ricu(paste0("HTTP ", status, " for ", file_url))
    invisible(NULL)
  }

  warn_dots(..., ok_args = "token")

  chksums <- tryCatch(get_sha256(url, user, pass), error = function(e) NULL)

  if (is.null(chksums)) {
    user    <- get_cred(user, "RICU_PHYSIONET_USER", "PhysioNet username: ")
    pass    <- get_cred(pass, "RICU_PHYSIONET_PASS", "PhysioNet password: ")
    chksums <- get_sha256(url, user, pass)
  }

  avail <- vapply(chksums, `[[`, character(1L), 2L)
  miss  <- setdiff(files, avail)
  if (length(miss) > 0L) stop("Files not in SHA256SUMS: ", paste(miss, collapse = ", "))

  todo      <- chksums[match(files, avail)]
  files_dl  <- vapply(todo, `[[`, character(1L), 2L)
  checks_v  <- vapply(todo, `[[`, character(1L), 1L)
  paths     <- file.path(dest_folder, files_dl)
  urls_dl   <- paste(url, files_dl, sep = "/")

  ensure_dirs(unique(dirname(paths)))
  unlink(paths)

  message("Fetching file sizes...")
  sizes <- vapply(urls_dl, get_size, numeric(1L))

  if (isTRUE(verbose)) {
    total <- sum(sizes, na.rm = TRUE)
    message("Downloading ", length(files_dl), " file(s) for ", src,
            if (total > 0) paste0("  [total: ~", format_bytes(total), "]") else "")
  }

  Map(dl_one, urls_dl, sizes, paths)

  if (isTRUE(verbose)) msg_ricu("Comparing checksums")
  checks <- mapply(check_file_sha256, paths, checks_v)
  if (!all(checks)) {
    warning("Checksum mismatch for: ",
            paste(files_dl[!checks], collapse = ", "), call. = FALSE)
  }
  invisible(NULL)
}


#' Download raw EHR tables from PhysioNet.
#'
#' @param src_name    Source name (must match an entry in \code{data-sources.json}).
#' @param tables      Character vector of table names to download.
#' @param data_dir    Destination directory.
#' @param config_path Path to the data-sources JSON.
#' @export
download_data <- function(src_name, tables, data_dir,
                          config_path = system.file("config", "data-sources.json",
                                                    package = "sciehr")) {
  src_cfg     <- load_src_config(config_path, src_name)
  base_url    <- src_cfg$url
  tables_json <- src_cfg$tables

  missing <- setdiff(tables, names(tables_json))
  if (length(missing) > 0L) {
    stop("Tables not in config: ", paste(missing, collapse = ", "))
  }

  message("\n*** Downloading from PhysioNet: ", src_name, " ***\n")

  files_dl <- vapply(tables, function(tbl) tables_json[[tbl]]$files, character(1L))
  download_check_data(dest_folder = data_dir, files = files_dl,
                      url = base_url, src = src_name)
  invisible(files_dl)
}
