#!/usr/bin/env Rscript

## 02_standardize_gsea_outputs.R
##
## Converts raw GSEAPreranked report TSV files into compact, OmicsKit-ready
## standardized TSVs.

.libPaths(c(path.expand("~/R/library"), .libPaths()))
options(stringsAsFactors = FALSE)

suppressPackageStartupMessages({
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop(
      "Package 'data.table' is required. Install it with: install.packages('data.table')",
      call. = FALSE
    )
  }
  library(data.table)
})

args <- commandArgs(trailingOnly = FALSE)
file_arg <- "--file="
script_path <- sub(file_arg, "", args[grep(file_arg, args)])

if (length(script_path) == 0 || !nzchar(script_path[1])) {
  script_path <- "preranked/scripts/02_standardize_gsea_outputs.R"
} else {
  script_path <- script_path[1]
}

script_path <- normalizePath(script_path, mustWork = FALSE)
repo_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = FALSE)

preranked_dir <- file.path(repo_root, "preranked")
config_file <- file.path(preranked_dir, "config", "brca_preranked_config.tsv")
example_dir <- file.path(preranked_dir, "examples", "brca")
raw_gsea_dir <- file.path(example_dir, "raw_gsea")
omicskit_ready_dir <- file.path(example_dir, "omicskit_ready")

dir.create(omicskit_ready_dir, showWarnings = FALSE, recursive = TRUE)

if (!file.exists(config_file)) {
  stop("Config file not found: ", config_file, call. = FALSE)
}

config <- data.table::fread(config_file)

required_config_cols <- c("comparison", "collection", "output_label")
missing_config <- setdiff(required_config_cols, names(config))

if (length(missing_config) > 0) {
  stop(
    "Config file missing columns: ",
    paste(missing_config, collapse = ", "),
    call. = FALSE
  )
}

normalize_names <- function(x) {
  y <- names(x)
  y <- gsub("^#", "", y)
  y <- gsub("[[:space:]]+", "_", y)
  y <- gsub("-", "_", y)
  y <- gsub("/", "_", y)
  y <- gsub("\\.+", "_", y)
  y <- gsub("__+", "_", y)
  names(x) <- y
  x
}

pick_col <- function(data, candidates, label, file) {
  hit <- intersect(candidates, names(data))

  if (length(hit) == 0) {
    stop(
      "Missing ", label, " column in ", basename(file), "\n",
      "Expected one of: ", paste(candidates, collapse = ", "), "\n",
      "Observed: ", paste(names(data), collapse = ", "),
      call. = FALSE
    )
  }

  hit[1]
}

find_reports <- function(comparison, collection) {
  run_dir <- file.path(raw_gsea_dir, comparison, collection)

  if (!dir.exists(run_dir)) {
    stop("Raw GSEA directory not found: ", run_dir, call. = FALSE)
  }

  files <- list.files(
    run_dir,
    pattern = "gsea_report_for_.*\\.tsv$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(files) == 0) {
    stop("No gsea_report_for_*.tsv files found in: ", run_dir, call. = FALSE)
  }

  files
}

infer_report_side <- function(file) {
  base <- basename(file)

  if (grepl("_pos_", base)) {
    return("pos")
  }

  if (grepl("_neg_", base)) {
    return("neg")
  }

  NA_character_
}

standardize_report <- function(file, comparison, collection, output_label) {
  x <- data.table::fread(file)
  x <- normalize_names(x)

  pathway_col <- pick_col(
    x,
    c("NAME", "Gene_Set", "GeneSet", "pathway", "Pathway"),
    "pathway",
    file
  )

  size_col <- pick_col(
    x,
    c("SIZE", "Size", "size"),
    "size",
    file
  )

  es_col <- pick_col(
    x,
    c("ES"),
    "ES",
    file
  )

  nes_col <- pick_col(
    x,
    c("NES"),
    "NES",
    file
  )

  p_col <- pick_col(
    x,
    c("NOM_p_val", "NOM_p_value", "NOM_pval", "NOM_p", "pvalue", "PValue"),
    "nominal p-value",
    file
  )

  fdr_col <- pick_col(
    x,
    c("FDR_q_val", "FDR_q_value", "FDR", "padj", "qvalue"),
    "FDR q-value",
    file
  )

  fwer_col <- pick_col(
    x,
    c("FWER_p_val", "FWER_p_value", "FWER"),
    "FWER p-value",
    file
  )

  out <- data.table::data.table(
    pathway = as.character(x[[pathway_col]]),
    collection = collection,
    comparison = comparison,
    method = "GSEAPreranked",
    source = "DanielGarbozo/GSEA-Pipeline/preranked",
    rank_metric = "limma_t_stat_or_user_supplied_rnk",
    ES = suppressWarnings(as.numeric(x[[es_col]])),
    NES = suppressWarnings(as.numeric(x[[nes_col]])),
    pvalue = suppressWarnings(as.numeric(x[[p_col]])),
    padj = suppressWarnings(as.numeric(x[[fdr_col]])),
    FWER = suppressWarnings(as.numeric(x[[fwer_col]])),
    size = suppressWarnings(as.integer(x[[size_col]])),
    output_label = output_label,
    report_side = infer_report_side(file),
    source_file = basename(file)
  )

  if ("RANK_AT_MAX" %in% names(x)) {
    out[, rank_at_max := x[["RANK_AT_MAX"]]]
  } else {
    out[, rank_at_max := NA]
  }

  if ("LEADING_EDGE" %in% names(x)) {
    out[, leading_edge := as.character(x[["LEADING_EDGE"]])]
  } else {
    out[, leading_edge := NA_character_]
  }

  if ("CORE_ENRICHMENT" %in% names(x)) {
    out[, core_enrichment := as.character(x[["CORE_ENRICHMENT"]])]
  } else {
    out[, core_enrichment := NA_character_]
  }

  out[, direction := data.table::fifelse(NES > 0, "positive", "negative")]
  out[, significant_fdr_0_25 := !is.na(padj) & padj < 0.25]
  out[, significant_fdr_0_05 := !is.na(padj) & padj < 0.05]

  out <- out[!is.na(pathway) & pathway != ""]

  ## data.table::setorder() cannot use expressions like -abs(NES), so create helper.
  out[, abs_NES := abs(NES)]
  data.table::setorder(out, padj, -abs_NES, pathway)
  out[, abs_NES := NULL]

  out[]
}

standardize_run <- function(comparison, collection, output_label) {
  files <- find_reports(comparison, collection)

  message("Standardizing: ", comparison, " / ", collection)
  message("  reports found: ", length(files))

  res <- data.table::rbindlist(
    lapply(
      files,
      standardize_report,
      comparison = comparison,
      collection = collection,
      output_label = output_label
    ),
    fill = TRUE
  )

  ## Remove duplicated pathway rows if both report files overlap.
  ## Keep the row with the lowest FDR, then strongest absolute NES.
  res[, abs_NES := abs(NES)]
  data.table::setorder(res, pathway, padj, -abs_NES)
  res <- res[!duplicated(pathway)]
  data.table::setorder(res, padj, -abs_NES, pathway)
  res[, abs_NES := NULL]

  out_file <- file.path(omicskit_ready_dir, paste0(output_label, ".tsv"))

  data.table::fwrite(
    res,
    out_file,
    sep = "\t",
    quote = FALSE
  )

  message("Saved: ", out_file)
  message("  rows: ", nrow(res))
  message("  FDR < 0.25: ", sum(res$significant_fdr_0_25, na.rm = TRUE))
  message("  FDR < 0.05: ", sum(res$significant_fdr_0_05, na.rm = TRUE))

  res
}

all_results <- list()

for (i in seq_len(nrow(config))) {
  comparison <- config$comparison[i]
  collection <- config$collection[i]
  output_label <- config$output_label[i]

  key <- paste(comparison, collection, sep = "__")

  all_results[[key]] <- standardize_run(
    comparison = comparison,
    collection = collection,
    output_label = output_label
  )
}

merged <- data.table::rbindlist(all_results, fill = TRUE)

merged[, abs_NES := abs(NES)]
data.table::setorder(merged, comparison, collection, padj, -abs_NES, pathway)
merged[, abs_NES := NULL]

merged_file <- file.path(
  omicskit_ready_dir,
  "GSEA_BRCA_all_comparisons_Hallmark_GO_BP.tsv"
)

data.table::fwrite(
  merged,
  merged_file,
  sep = "\t",
  quote = FALSE
)

message("Saved merged OmicsKit-ready file: ", merged_file)
message("Total rows: ", nrow(merged))
message("Done.")
