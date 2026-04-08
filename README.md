# GSEA Pipeline

This pipeline provides comprehensive tools for Gene Set Enrichment Analysis (GSEA), including preprocessing, running analyses, and post-processing workflows. It integrates multiple pathway enrichment methods for robust gene set analysis.

## Overview

The GSEA Pipeline consists of three layers:

1. **Data Retrieval & Preparation**: Download gene sets and prepare input data
2. **Enrichment Analysis**: Run GSEA using multiple algorithms (GSEA CLI, PADOG, CAMERA)
3. **Results Processing**: Merge, validate, and filter enrichment results

---

## Scripts by Category

### 1. Data Preparation & Retrieval

#### `retrieveMSigDB.py`
Retrieves gene sets from the MSigDB (Molecular Signatures Database) for enrichment analysis.

**Usage:**
```bash
python retrieveMSigDB.py -o output_directory
```

**Requirements:**
- Python 3.x
- Internet connection for database access

---

#### `final_genes.sh`
Extracts gene symbols from `.grp` files and appends them to a final output file. Useful for tracking genes included in the analysis.

**Usage:**
```bash
./final_genes.sh
```

**Requirements:**
- Bash shell
- `.grp` files from GSEA output

---

### 2. GSEA Execution (Deprecated but maintained for reference)

These scripts execute GSEA analysis. **Note:** Newer workflows (PADOG, CAMERA) are now preferred for most analyses, but these remain available for specific use cases.

**GSEA Installation & Configuration:**
Before running any GSEA scripts, ensure GSEA is properly installed. Refer to:
[GSEA User Guide - Running from Command Line](https://docs.gsea-msigdb.org/#GSEA/GSEA_User_Guide/Running_GSEA_from_the_Command_Line)

Key requirements:
- Java installed and accessible
- `gsea-cli.sh` script in your PATH or explicitly referenced
- Gene annotation files (`.chip`) matching your organism
- Gene set matrix files (`.gmt`) from MSigDB

---

#### `GSEA_script.sh`
Test version of GSEA execution with multiple comparisons built-in across multi collections. 
Useful for validating your GSEA setup before running large analyses.

**Configuration:**
Edit the script to set:
- `working_dir`: Base directory for all GSEA data
- `expression_data`: Path to expression data file (`.txt`)
- `phenotype_info`: Path to phenotype/class file (`.cls`)
- `matrix_dir`: Directory containing gene set files (`.gmt`)
- `chip_annotations`: Directory containing annotation files (`.chip`)
- `output_dir`: Where results will be saved

**Parameters:**
- `nperm`: Number of permutations (default: 10,000)
- `permute`: Permutation type (`gene_set` or `phenotype`)
- `metric`: Gene ranking metric (`Signal2Noise` or `log2_Ratio_of_Classes`)

**Key features:**
- 5 example comparisons (Ap_versus_An, Bp_versus_An, etc.)
- C3 TF/Legacy gene sets (MSigDB v2023.2)
- Proper handling of small sample sizes (`permute: gene_set`)
- Parallel execution with background jobs
- Timing information for monitoring

**Usage:**
```bash
./GSEA_script.sh
```

**Customization:**
Edit the script to modify:
- Gene set collections (change `c3.tft.tft_legacy.v2023.2.Hs.symbols.gmt`)
- Comparisons array
- Output labels
- Analysis parameters

---

### 3. Results Processing

#### `GSEA_merge.sh`
Merges and renames GSEA result files from multiple collections and comparisons into consolidated TSV files. Handles proper header inclusion to avoid duplication.

**Structure:**
```
Input:
  main_dir/
  ├── Collection1/
  │   ├── Comparison1_[timestamp]/
  │   │   ├── gsea_report_for_POSITIVE.tsv
  │   │   └── gsea_report_for_NEGATIVE.tsv
  │   └── Comparison2_[timestamp]/
  └── Collection2/
      └── ...

Output:
  destination_dir/
  ├── Collection1_Comparison1_merged.tsv
  ├── Collection1_Comparison2_merged.tsv
  ├── Collection2_Comparison1_merged.tsv
  └── ...
```

**Configuration:**
Edit the script to set:
- `main_dir`: Base directory containing GSEA results by collection
- `destination_dir`: Where merged files will be saved

**Usage:**
```bash
./GSEA_merge.sh
```

**Features:**
- Automatic collection and comparison name extraction
- Removes timestamps and GSEA-specific formatting
- Preserves header row only once in merged files
- Handles missing files gracefully


**Output:**
A consolidated file suitable for downstream analysis (filtering, visualization, etc.)

---

### 4. Alternative Pathway Enrichment Methods (R Workflows)

For more flexible and statistically robust pathway analysis, we provide R workflows based on established bioinformatics packages.

#### `padog_analysis.Rmd`
Pathway analysis workflow using **PADOG** (Pathway Analysis by Differential Gene Expression Ranking).

**Method:** 
PADOG ranks genes by differential expression and tests whether pathway genes are significantly ranked higher than expected by chance.

**Features:**
- Supports multiple gene set collections (GMT files)
- Multiple comparisons in a single run
- Parallel processing for speed
- FDR adjustment for multiple testing
- Significance filtering and output organization by collection

**Input requirements:**
- Gene expression count matrix (TSV file with gene symbols as rownames)
- Metadata file (Excel) with sample annotations and group assignments
- Gene set files (GMT format)

**Output:**
- CSV and RDS files per collection
- Total consolidated results across all collections
- Filtered significant gene sets (FDR < 0.25)

**Dependencies:**
```r
library(PADOG)
library(readxl)
library(dplyr)
library(stringr)
library(parallel)
library(doParallel)
library(limma)  # for voom
```

**Configuration:**
Edit the "Define paths" section to set:
- `main_dir`: Base directory for all data
- `genesets_dir`: Directory containing `.gmt` files
- `output_dir`: Where results will be saved
- `expression_file`: Path to count matrix
- `metadata_file`: Path to sample metadata

**Customization:**
- `comparisons`: Vector of comparison identifiers (e.g., `c("Bp_Ap", "Bp_An", ...)`)
- `Nmin`: Minimum number of genes in a pathway (default: 3)
- `NI`: Number of permutations (default: 500)
- `ncr`: Number of cores for parallel processing

**Usage:**
Open the Rmd file in RStudio and run chunks sequentially, or knit to HTML:
```r
rmarkdown::render("padog_analysis.Rmd", output_format = "html_document")
```

---

#### `camera_analysis.Rmd`
Gene set enrichment workflow using **CAMERA** (Correlation-adjusted MEan RAnk gene set test) from the `limma` package.

**Method:**
CAMERA tests whether genes in a pathway have concordant direction of change using mean rank statistics adjusted for inter-gene correlation.

**Features:**
- Efficient rank-based testing
- Accounts for inter-gene correlation
- Supports both up and down regulation detection
- Multiple collections and comparisons
- Trend-based variance modeling

**Input requirements:**
- Gene expression count matrix (TSV file with gene symbols as rownames)
- Metadata file (Excel) with sample annotations
- Gene set files (GMT format)

**Output:**
- CSV and RDS files per collection
- Total consolidated results
- Significance-filtered results (FDR < 0.25)

**Dependencies:**
```r
library(limma)    # for camera() and voom()
library(readxl)
library(dplyr)
library(stringr)
```

**Configuration:**
Edit the "Define paths" section to set:
- `main_dir`: Base directory for all data
- `genesets_dir`: Directory containing `.gmt` files
- `output_dir`: Where results will be saved
- `expression_file`: Path to count matrix
- `metadata_file`: Path to sample metadata

**Customization:**
- `comparisons`: Vector of comparison identifiers
- `inter.gene.cor`: Inter-gene correlation estimate (default: 0.01)
- `use.ranks`: Whether to use gene ranks (default: FALSE)
- `trend.var`: Whether to allow trend in variances (default: TRUE)

**Usage:**
Open the Rmd file in RStudio and run chunks sequentially, or knit:
```r
rmarkdown::render("camera_analysis.Rmd", output_format = "html_document")
```

---

#### `md5compare.py`
Compares MD5 checksums between files to ensure data integrity during transfer or processing.

**Usage:**
```bash
python md5compare.py file1 file2
```

**Output:**
Reports whether files are identical (matching MD5 checksums) or different.

---

## Workflow Examples

### Complete GSEA Analysis (CLI-based)

```bash
# 1. Retrieve gene sets
python retrieveMSigDB.py -o ./gene_sets

# 2. Prepare expression data and phenotype file

# 3. Run GSEA 
./GSEA_script.sh

# 4. Merge results
./GSEA_merge.sh

# 5. Extract final genes (optional)
./final_genes.sh
```

### Pathway Analysis with R (Recommended for flexibility)

```bash
# 1. Retrieve and prepare gene sets
python retrieveMSigDB.py -o ./gene_sets

# 2. In R/RStudio:
#    - Open padog_analysis.Rmd or camera_analysis.Rmd
#    - Configure paths section
#    - Run analysis chunks
#    - Review results and filtered significant pathways

# 3. Compare results between methods (PADOG, CAMERA)
#    - Both produce CSV and RDS outputs
#    - Allows cross-validation of findings
```

---

## System Requirements

- **Bash scripts**: Bash shell (Unix/Linux/WSL)
- **Python scripts**: Python 3.6+
- **R workflows**: R 4.0+, RStudio (recommended)
- **GSEA CLI**: Java, GSEA CLI tool installed and configured
- **R packages**: limma, PADOG, readxl, dplyr, stringr, parallel, doParallel

## Installation Notes

### For WSL/Windows with Git Bash:
```bash
# Ensure scripts are executable
chmod +x *.sh

# For R scripts, use RStudio or:
Rscript -e "rmarkdown::render('script.Rmd')"
```

### For Linux/Mac:
All bash scripts should work directly. Ensure `gsea-cli.sh` is in PATH:
```bash
export PATH="/path/to/GSEA:$PATH"
```

---

## Contributing

When adding new scripts:
1. Follow the naming convention: `METHOD_analysis_[context]_v[number].sh|Rmd`
2. Include a clear header with author, date, and purpose
3. Document input/output files clearly
4. Provide example usage in comments
5. Test before submitting a pull request

---

## References

- [GSEA Official Documentation](https://www.gsea-msigdb.org/)
- [GSEA Command Line Guide](https://docs.gsea-msigdb.org/#GSEA/GSEA_User_Guide/Running_GSEA_from_the_Command_Line)
- [MSigDB Database](https://www.gsea-msigdb.org/gsea/msigdb)
- [limma R Package](https://bioconductor.org/packages/release/bioc/html/limma.html)
- [PADOG R Package](https://bioconductor.org/packages/release/bioc/html/PADOG.html)

---

## License

See LICENSE file for details.

---

**Last updated:** February 2025
**Maintainers:** BigMindLab contributors
