#!/usr/bin/env Rscript

## 00_make_rnk_from_dea.R
##
## Converts OmicsKit DEA TSV files into GSEAPreranked .rnk files.
##
## Input:
##   preranked/examples/brca/input/dea/
##     - DEA_RNAseq_limma_ERpositive_vs_ERnegative.tsv
##     - DEA_RNAseq_limma_Tumor_vs_Normal.tsv
##
## Output:
##   preranked/examples/brca/rnk/
##     - BRCA_ERpositive_vs_ERnegative.rnk
##     - BRCA_Tumor_vs_Normal.rnk
##     - BRCA_ERpositive_vs_ERnegative_metadata.tsv
##     - BRCA_Tumor_vs_Normal_metadata.tsv
##
## RNK format:
##   Two tab-separated columns, no header:
##     GENE_SYMBOL    ranking_metric
##
## Recommended ranking metric:
##   limma moderated t-statistic, using column `stat` or `t`.

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

## Resolve repository root robustly when executed as:
##   Rscript preranked/scripts/00_make_rnk_from_dea.R
args <- commandArgs(trailingOnly = FALSE)
file_arg <- "--file="
script_path <- sub(file_arg, "", args[grep(file_arg, args)])

if (length(script_path) == 0 || !nzchar(script_path[1])) {
  script_path <- "preranked/scripts/00_make_rnk_from_dea.R"
} else {
  script_path <- script_path[1]
}

script_path <- normalizePath(script_path, mustWork = FALSE)
repo_root <- normalizePath(file.path(dirname(script_path), "..", ".."), mustWork = FALSE)

example_dir <- file.path(repo_root, "preranked", "examples", "brca")
dea_dir <- file.path(example_dir, "input", "dea")
rnk_dir <- file.path(example_dir, "rnk")

dir.create(rnk_dir, showWarnings = FALSE, recursive = TRUE)

dea_files <- list(
  ERpositive_vs_ERnegative = file.path(
    dea_dir,
    "DEA_RNAseq_limma_ERpositive_vs_ERnegative.tsv"
  ),
  Tumor_vs_Normal = file.path(
    dea_dir,
    "DEA_RNAseq_limma_Tumor_vs_Normal.tsv"
  )
)

out_files <- list(
  ERpositive_vs_ERnegative = file.path(
    rnk_dir,
    "BRCA_ERpositive_vs_ERnegative.rnk"
  ),
  Tumor_vs_Normal = file.path(
    rnk_dir,
    "BRCA_Tumor_vs_Normal.rnk"
  )
)

pick_first_col <- function(x, candidates, label) {
  hit <- intersect(candidates, names(x))

  if (length(hit) == 0) {
    stop(
      "Missing ", label, " column. Expected one of: ",
      paste(candidates, collapse = ", "),
      "\nObserved columns: ", paste(names(x), collapse = ", "),
      call. = FALSE
    )
  }

  hit[1]
}

make_rnk <- function(dea_file, out_file, comparison) {
  if (!file.exists(dea_file)) {
    stop(
      "DEA file not found: ", dea_file, "\n",
      "Place the DEA TSV in: ", dirname(dea_file),
      call. = FALSE
    )
  }

  dea <- data.table::fread(dea_file)

  gene_col <- pick_first_col(
    dea,
    candidates = c("gene", "gene_symbol", "Gene", "GeneSymbol", "SYMBOL"),
    label = "gene"
  )

  if ("stat" %in% names(dea)) {
    rank_col <- "stat"
    rank_metric <- "limma_t_stat"
  } else if ("t" %in% names(dea)) {
    rank_col <- "t"
    rank_metric <- "limma_t_stat"
  } else if (
    "logFC" %in% names(dea) &&
      ("pvalue" %in% names(dea) || "P.Value" %in% names(dea))
  ) {
    p_col <- if ("pvalue" %in% names(dea)) "pvalue" else "P.Value"

    dea[
      ,
      rank_value_tmp := sign(as.numeric(logFC)) *
        -log10(pmax(as.numeric(get(p_col)), .Machine$double.xmin))
    ]

    rank_col <- "rank_value_tmp"
    rank_metric <- "signed_minus_log10_pvalue"
  } else {
    stop(
      "DEA file must contain either `stat`/`t`, or `logFC` plus `pvalue`/`P.Value`: ",
      dea_file,
      call. = FALSE
    )
  }

  rnk <- dea[
    ,
    .(
      gene = toupper(trimws(as.character(get(gene_col)))),
      rank_value = suppressWarnings(as.numeric(get(rank_col)))
    )
  ]

  rnk <- rnk[!is.na(gene) & gene != "" & is.finite(rank_value)]

  if (nrow(rnk) == 0) {
    stop(
      "No valid genes remained after filtering missing gene names and ranking values: ",
      dea_file,
      call. = FALSE
    )
  }

  ## Keep the strongest absolute ranking value per gene.
  ## data.table::setorder() does not accept expressions such as -abs(rank_value),
  ## so we create an explicit helper column.
  rnk[, abs_rank_value := abs(rank_value)]
  data.table::setorder(rnk, gene, -abs_rank_value)
  rnk <- rnk[!duplicated(gene)]
  rnk[, abs_rank_value := NULL]

  ## Sort descending for GSEAPreranked.
  data.table::setorder(rnk, -rank_value, gene)

  ## Break exact ranking ties deterministically.
  ## GSEAPreranked warns against duplicated ranking values because ties may create
  ## arbitrary ordering. The perturbation is tiny and preserves practical ranking.
  if (anyDuplicated(rnk$rank_value) > 0) {
    eps <- seq_len(nrow(rnk)) * .Machine$double.eps
    rnk[, rank_value := rank_value + eps]
    data.table::setorder(rnk, -rank_value, gene)
  }

  data.table::fwrite(
    rnk[, .(gene, rank_value)],
    out_file,
    sep = "\t",
    col.names = FALSE,
    quote = FALSE
  )

  metadata <- data.table::data.table(
    comparison = comparison,
    rnk_file = basename(out_file),
    source_dea = basename(dea_file),
    gene_column = gene_col,
    rank_metric = rank_metric,
    n_genes = nrow(rnk),
    min_rank = min(rnk$rank_value, na.rm = TRUE),
    max_rank = max(rnk$rank_value, na.rm = TRUE),
    duplicated_rank_values_after_tie_break = anyDuplicated(rnk$rank_value),
    created = as.character(Sys.time())
  )

  metadata_file <- sub("\\.rnk$", "_metadata.tsv", out_file)

  data.table::fwrite(
    metadata,
    metadata_file,
    sep = "\t",
    quote = FALSE
  )

  message("Created: ", out_file)
  message("  genes: ", nrow(rnk))
  message("  metric: ", rank_metric)
  message("  metadata: ", metadata_file)

  invisible(rnk)
}

for (comparison in names(dea_files)) {
  make_rnk(
    dea_file = dea_files[[comparison]],
    out_file = out_files[[comparison]],
    comparison = comparison
  )
}
