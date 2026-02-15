# R Script to help convert knitr chunk options to Quarto hashpipe format
# This script analyzes .qmd files and reports chunks needing conversion

library(stringr)
library(cli)

# Function to extract chunk headers from a file
extract_chunk_headers <- function(file_path) {
  lines <- readLines(file_path, warn = FALSE)
  chunk_pattern <- "^```\\{r[^}]*\\}"

  chunk_lines <- grep(chunk_pattern, lines, value = TRUE)
  chunk_numbers <- grep(chunk_pattern, lines)

  if (length(chunk_lines) > 0) {
    data.frame(
      file = basename(file_path),
      line = chunk_numbers,
      header = chunk_lines,
      stringsAsFactors = FALSE
    )
  } else {
    NULL
  }
}

# Function to check if chunk has options in header (needs conversion)
needs_conversion <- function(header) {
  # Check if there are options after {r (more than just label)
  # Simple chunks: ```{r} or ```{r label}
  # Complex chunks: ```{r label, option=value}

  str_detect(header, ",|=") & !str_detect(header, "^```\\{r\\}$")
}

# Function to parse chunk options
parse_chunk_options <- function(header) {
  # Remove ```{r and closing }
  content <- str_replace(header, "^```\\{r\\s*", "")
  content <- str_replace(content, "\\}$", "")

  if (content == "") return(list(label = NULL, options = list()))

  # Split by comma (but not within quotes)
  parts <- str_split(content, ",(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)")[[1]]
  parts <- str_trim(parts)

  # First part might be label (no =)
  if (!str_detect(parts[1], "=")) {
    label <- parts[1]
    options <- parts[-1]
  } else {
    label <- NULL
    options <- parts
  }

  # Parse options
  opt_list <- list()
  for (opt in options) {
    if (str_detect(opt, "=")) {
      kv <- str_split(opt, "=", n = 2)[[1]]
      key <- str_trim(kv[1])
      value <- str_trim(kv[2])
      opt_list[[key]] <- value
    }
  }

  list(label = label, options = opt_list)
}

# Function to convert option names
convert_option_name <- function(name) {
  conversions <- c(
    "fig.cap" = "fig-cap",
    "fig.width" = "fig-width",
    "fig.height" = "fig-height",
    "fig.alt" = "fig-alt",
    "out.width" = "out-width",
    "out.height" = "out-height",
    "fig.align" = "fig-align",
    "fig.path" = "fig-path",
    "tab.cap" = "tbl-cap"
  )

  if (name %in% names(conversions)) {
    conversions[[name]]
  } else {
    name
  }
}

# Function to convert option values
convert_option_value <- function(value) {
  # Convert R booleans to YAML booleans
  if (value %in% c("TRUE", "T")) return("true")
  if (value %in% c("FALSE", "F")) return("false")
  if (value == "NULL") return("null")

  # Remove outer quotes if present for strings
  value
}

# Function to generate hashpipe options
generate_hashpipe <- function(parsed, has_fig_cap = FALSE) {
  lines <- c()

  # Determine label prefix
  label <- parsed$label
  if (!is.null(label)) {
    # Add fig- prefix if has fig.cap
    if (has_fig_cap && !str_detect(label, "^fig-")) {
      label <- paste0("fig-", label)
    }
    lines <- c(lines, paste0("#| label: ", label))
  }

  # Convert options
  for (name in names(parsed$options)) {
    new_name <- convert_option_name(name)
    new_value <- convert_option_value(parsed$options[[name]])
    lines <- c(lines, paste0("#| ", new_name, ": ", new_value))
  }

  lines
}

# Main analysis function
analyze_qmd_files <- function(directory = ".") {
  qmd_files <- list.files(directory, pattern = "\\.qmd$", full.names = TRUE)

  cli_h1("Analyzing chunk options")
  cli_alert_info("Scanning {.val {length(qmd_files)}} {.file .qmd} files in {.path {directory}}")

  all_chunks <- do.call(rbind, lapply(qmd_files, extract_chunk_headers))

  if (is.null(all_chunks) || nrow(all_chunks) == 0) {
    cli_alert_warning("No R code chunks found")
    return(invisible(NULL))
  }

  cli_alert_info("Found {.val {nrow(all_chunks)}} total R chunks")


  # Filter to chunks needing conversion
  all_chunks$needs_conversion <- sapply(all_chunks$header, needs_conversion)

  to_convert <- all_chunks[all_chunks$needs_conversion, ]

  if (nrow(to_convert) == 0) {
    cli_alert_success("All chunks already use hashpipe format!")
    return(invisible(NULL))
  }

  cli_alert_warning("Found {.val {nrow(to_convert)}} chunk{?s} needing conversion")
  cli_rule()

  for (i in seq_len(nrow(to_convert))) {
    row <- to_convert[i, ]
    parsed <- parse_chunk_options(row$header)
    has_fig_cap <- "fig.cap" %in% names(parsed$options)

    cli_h2("{.file {row$file}} (line {.val {row$line}})")

    cli_text("{.strong Original:}")
    cli_code(row$header)

    cli_text("{.strong Convert to:}")
    hashpipe <- generate_hashpipe(parsed, has_fig_cap)
    cli_code(c("```{r}", hashpipe))

    if (i < nrow(to_convert)) {
      cli_rule()
    }
  }

  cli_h1("Summary")

  # Group by file
  file_counts <- table(to_convert$file)
  n_files <- length(file_counts)

  cli_text("{.val {n_files}} file{?s} with chunks to convert:")

  for (i in seq_along(file_counts)) {
    n <- as.integer(file_counts[i])
    fname <- names(file_counts)[i]
    cli_bullets(c("*" = "{.file {fname}}: {.val {n}} chunk{?s}"))
  }

  invisible(to_convert)
}

# Run analysis
if (interactive()) {
  analyze_qmd_files()
}
