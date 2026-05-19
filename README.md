# GSEA-Pipeline

A reproducible workflow collection for **Gene Set Enrichment Analysis (GSEA)** and related pathway-enrichment analyses.

This repository supports three complementary analysis modes:

1. **Classic GSEA CLI** — for expression matrices plus phenotype/class labels.
2. **GSEAPreranked** — for differential-expression results or ranked gene lists.
3. **R-based pathway methods** — PADOG and CAMERA workflows for count matrices and metadata.

The repository is designed for exploratory pathway analysis, reproducible batch execution, and downstream integration with external projects such as **OmicsKit**.

---

## Repository layout

```text
GSEA-Pipeline/
├── GSEA_script.sh
├── GSEA_merge.sh
├── retrieveMSigDB.py
├── final_genes.sh
├── md5compare.py
├── padog_analysis.Rmd
├── camera_analysis.Rmd
├── preranked/
│   ├── README.md
│   ├── .gitignore
│   ├── config/
│   │   └── brca_preranked_config.tsv
│   ├── scripts/
│   │   ├── 00_make_rnk_from_dea.R
│   │   ├── 01_run_gsea_preranked.sh
│   │   ├── 02_standardize_gsea_outputs.R
│   │   └── 03_copy_omicskit_ready_outputs.sh
│   └── examples/
│       └── brca/
│           ├── README.md
│           ├── input/
│           │   ├── dea/
│           │   └── gmt/
│           ├── rnk/
│           ├── raw_gsea/
│           └── omicskit_ready/
└── old/
```

---

## Which workflow should I use?

### Use `preranked/` when you already have DEA results

Use this mode when your input is a differential-expression table with gene-level statistics, such as:

```text
gene    logFC    pvalue    padj    stat
ESR1    ...
GATA3   ...
```

This is the recommended workflow for **OmicsKit BRCA examples**, where the ranked lists are derived from RNA-seq DEA results.

Typical use cases:

- limma differential-expression results.
- DESeq2 results after adding a ranking statistic.
- Any gene-level table that can be converted to `.rnk`.
- Cases where normalized counts and `.cls` files are not available.

### Use `GSEA_script.sh` for classic GSEA

Use this mode when you have:

- an expression matrix,
- a phenotype `.cls` file,
- gene sets in `.gmt` format,
- and optionally a `.chip` annotation file.

This is the original command-line GSEA workflow.

### Use `padog_analysis.Rmd` or `camera_analysis.Rmd` for R-native workflows

Use these when you want to run pathway analysis entirely inside R from count matrices and sample metadata.

---

## Quick start: GSEAPreranked BRCA workflow

The BRCA example runs four analyses:

```text
ERpositive_vs_ERnegative × Hallmark
ERpositive_vs_ERnegative × GO_BP
Tumor_vs_Normal          × Hallmark
Tumor_vs_Normal          × GO_BP
```

### 1. Prepare DEA inputs

Place OmicsKit RNA-seq DEA tables in:

```text
preranked/examples/brca/input/dea/
```

Expected files:

```text
DEA_RNAseq_limma_ERpositive_vs_ERnegative.tsv
DEA_RNAseq_limma_Tumor_vs_Normal.tsv
```

### 2. Create ranked lists

Run:

```bash
Rscript preranked/scripts/00_make_rnk_from_dea.R
```

Expected outputs:

```text
preranked/examples/brca/rnk/BRCA_ERpositive_vs_ERnegative.rnk
preranked/examples/brca/rnk/BRCA_Tumor_vs_Normal.rnk
preranked/examples/brca/rnk/BRCA_ERpositive_vs_ERnegative_metadata.tsv
preranked/examples/brca/rnk/BRCA_Tumor_vs_Normal_metadata.tsv
```

Each `.rnk` file has two tab-separated columns and no header:

```text
GENE_SYMBOL    ranking_metric
```

By default, the script uses the limma moderated `t` statistic from `stat` or `t`.

### 3. Add MSigDB GMT files

Place MSigDB GMT files in:

```text
preranked/examples/brca/input/gmt/
```

Expected file patterns:

```text
h.all.*.Hs.symbols.gmt
c5.go.bp.*.Hs.symbols.gmt
```

GMT files are intentionally ignored by git. Download them directly from MSigDB according to your registration and usage terms.

### 4. Configure GSEA CLI

For WSL/Linux, export the GSEA CLI path:

```bash
export GSEA_CLI="$HOME/tools/GSEA_Linux_4.4.0/gsea-cli.sh"
```

Optional parameters:

```bash
export N_PERM=1000
export SET_MIN=15
export SET_MAX=500
export SEED=2025
export SCORING_SCHEME=weighted
export MAX_JOBS=4
```

### 5. Run all GSEAPreranked jobs

```bash
bash preranked/scripts/01_run_gsea_preranked.sh
```

Raw GSEA reports are written to:

```text
preranked/examples/brca/raw_gsea/
```

This folder is intentionally ignored by git because GSEA creates large HTML reports and timestamped output directories.

### 6. Standardize GSEA outputs

```bash
Rscript preranked/scripts/02_standardize_gsea_outputs.R
```

Expected outputs:

```text
preranked/examples/brca/omicskit_ready/GSEA_ERpositive_vs_ERnegative_Hallmark.tsv
preranked/examples/brca/omicskit_ready/GSEA_ERpositive_vs_ERnegative_GO_BP.tsv
preranked/examples/brca/omicskit_ready/GSEA_Tumor_vs_Normal_Hallmark.tsv
preranked/examples/brca/omicskit_ready/GSEA_Tumor_vs_Normal_GO_BP.tsv
preranked/examples/brca/omicskit_ready/GSEA_BRCA_all_comparisons_Hallmark_GO_BP.tsv
```

### 7. Copy outputs to OmicsKit

```bash
bash preranked/scripts/03_copy_omicskit_ready_outputs.sh ../OmicsKit
```

This copies standardized pathway results and `.rnk` files to:

```text
OmicsKit/inst/extdata/brca/gsea_outputs/
```

---

## Output contract for OmicsKit

Files in `preranked/examples/brca/omicskit_ready/` are standardized for import by:

```text
OmicsKit/data-raw/brca/05_import_gsea_pipeline_outputs_brca.R
```

Each standardized TSV contains:

```text
pathway
collection
comparison
method
source
rank_metric
ES
NES
pvalue
padj
FWER
size
output_label
report_side
source_file
rank_at_max
leading_edge
core_enrichment
direction
significant_fdr_0_25
significant_fdr_0_05
```

The merged file is:

```text
GSEA_BRCA_all_comparisons_Hallmark_GO_BP.tsv
```

---

## Classic GSEA CLI workflow

`GSEA_script.sh` runs command-line GSEA from expression data and phenotype labels.

Use this workflow when you have:

```text
expression matrix  +  phenotype .cls file  +  GMT files
```

Main inputs configured inside the script:

```text
working_dir
expression_data
phenotype_info
matrix_dir
chip_annotations
output_dir
```

Run:

```bash
bash GSEA_script.sh
```

The script is useful for validating a classic GSEA installation and running multiple comparisons across selected gene-set collections.

---

## Merging classic GSEA outputs

`GSEA_merge.sh` consolidates GSEA report files across collections and comparisons.

Run:

```bash
bash GSEA_merge.sh
```

Configure these variables inside the script:

```text
main_dir
destination_dir
```

The script is designed for classic GSEA output folders containing positive and negative enrichment reports.

---

## R-based pathway workflows

### PADOG

`padog_analysis.Rmd` runs pathway analysis using PADOG.

Inputs:

```text
count matrix
sample metadata
GMT files
```

Typical dependencies:

```r
library(PADOG)
library(readxl)
library(dplyr)
library(stringr)
library(parallel)
library(doParallel)
library(limma)
```

Render:

```r
rmarkdown::render("padog_analysis.Rmd", output_format = "html_document")
```

### CAMERA

`camera_analysis.Rmd` runs CAMERA from the `limma` package.

Inputs:

```text
count matrix
sample metadata
GMT files
```

Typical dependencies:

```r
library(limma)
library(readxl)
library(dplyr)
library(stringr)
```

Render:

```r
rmarkdown::render("camera_analysis.Rmd", output_format = "html_document")
```

---

## Utility scripts

### `retrieveMSigDB.py`

Retrieves gene-set files from MSigDB-compatible sources.

```bash
python retrieveMSigDB.py -o output_directory
```

### `final_genes.sh`

Extracts gene symbols from `.grp` files and appends them to a consolidated output.

```bash
bash final_genes.sh
```

### `md5compare.py`

Compares MD5 checksums between files.

```bash
python md5compare.py file1 file2
```

---

## Git tracking policy

Recommended to commit:

```text
preranked/README.md
preranked/.gitignore
preranked/config/*.tsv
preranked/scripts/*.R
preranked/scripts/*.sh
preranked/examples/brca/README.md
preranked/examples/brca/input/dea/*.tsv
preranked/examples/brca/rnk/*.rnk
preranked/examples/brca/rnk/*_metadata.tsv
preranked/examples/brca/omicskit_ready/*.tsv
```

Recommended not to commit:

```text
preranked/examples/brca/input/gmt/*.gmt
preranked/examples/brca/input/gmt/*.zip
preranked/examples/brca/raw_gsea/
```

Rationale:

- MSigDB GMT files may have access and licensing restrictions.
- Raw GSEA reports are large, timestamped, and reproducible.
- Standardized outputs in `omicskit_ready/` are compact and stable.

---

## System requirements

### Shell

```text
Bash
Linux, macOS, or WSL
```

### Python

```text
Python 3.6+
```

### R

```text
R 4.0+
data.table
limma
PADOG
readxl
dplyr
stringr
parallel
doParallel
```

### GSEA CLI

```text
GSEA 4.x
Java or bundled JDK
```

For WSL, the tested pattern is:

```bash
export GSEA_CLI="$HOME/tools/GSEA_Linux_4.4.0/gsea-cli.sh"
```

---

## Troubleshooting

### GSEAPreranked finishes immediately

Check logs:

```bash
find preranked/examples/brca/raw_gsea -name "*.log"
tail -50 <log_file>
```

Common causes:

```text
Unrecognized option: -permute
Unrecognized option: -gui
missing -rnk
missing -gmx
```

Use only the parameters accepted by GSEAPreranked:

```text
-rnk
-gmx
-collapse
-nperm
-scoring_scheme
-rpt_label
-rnd_seed
-set_min
-set_max
-plot_top_x
-out
```

### GSEAPreranked jobs keep running after the launcher exits

This usually means background jobs were started from a subshell. Use the corrected launcher that stores process IDs and waits on each PID.

Check active processes:

```bash
pgrep -af "GSEAPreranked|gsea-cli|java"
```

### `data.table::setorder()` error with `abs`

Do not use expressions like:

```r
setorder(x, -abs(NES))
```

Create a helper column first:

```r
x[, abs_NES := abs(NES)]
setorder(x, -abs_NES)
x[, abs_NES := NULL]
```

---

## References

- GSEA official website: <https://www.gsea-msigdb.org/>
- GSEA command-line documentation: <https://docs.gsea-msigdb.org/>
- MSigDB: <https://www.gsea-msigdb.org/gsea/msigdb>
- limma: <https://bioconductor.org/packages/limma/>
- PADOG: <https://bioconductor.org/packages/PADOG/>

---

## License

See `LICENSE`.

---

## Maintainers

BigMindLab contributors.

Last updated: May 2026
