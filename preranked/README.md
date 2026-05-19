# GSEAPreranked workflow

This folder contains a **GSEAPreranked** workflow for cases where the input is already a ranked gene list (`.rnk`) rather than normalized counts plus phenotype `.cls` files.

This is intended as a separate variant of the original `GSEA_script.sh` workflow. The original script runs classic GSEA using expression data and phenotype labels. This folder runs GSEAPreranked using ranked lists.

## Main use case

The BRCA example is designed for OmicsKit outputs:

- `ERpositive_vs_ERnegative`
- `Tumor_vs_Normal`

Gene-set collections expected:

- Hallmark
- GO Biological Process

## Folder structure

```text
preranked/
├── README.md
├── config/
│   └── brca_preranked_config.tsv
├── scripts/
│   ├── 00_make_rnk_from_dea.R
│   ├── 01_run_gsea_preranked.sh
│   ├── 02_standardize_gsea_outputs.R
│   └── 03_copy_omicskit_ready_outputs.sh
└── examples/
    └── brca/
        ├── README.md
        ├── input/
        │   ├── dea/
        │   └── gmt/
        ├── rnk/
        ├── raw_gsea/
        └── omicskit_ready/
```

## Expected input files

If you already have `.rnk` files, place them here:

```text
preranked/examples/brca/rnk/
```

Expected files:

```text
BRCA_ERpositive_vs_ERnegative.rnk
BRCA_Tumor_vs_Normal.rnk
```

If you want to create `.rnk` files from DEA tables, place the DEA tables here:

```text
preranked/examples/brca/input/dea/
```

Expected files:

```text
DEA_RNAseq_limma_ERpositive_vs_ERnegative.tsv
DEA_RNAseq_limma_Tumor_vs_Normal.tsv
```

Then run:

```bash
Rscript preranked/scripts/00_make_rnk_from_dea.R
```

## GMT files

Place MSigDB GMT files here:

```text
preranked/examples/brca/input/gmt/
```

Expected examples:

```text
h.all.v2025.1.Hs.symbols.gmt
c5.go.bp.v2025.1.Hs.symbols.gmt
```

The GMT files are not committed by default. Download them directly from MSigDB according to your registration and usage terms.

## Run all GSEAPreranked analyses

Edit the GSEA CLI path if needed:

```bash
bash preranked/scripts/01_run_gsea_preranked.sh
```

By default, this runs:

```text
ERpositive_vs_ERnegative × Hallmark
ERpositive_vs_ERnegative × GO_BP
Tumor_vs_Normal × Hallmark
Tumor_vs_Normal × GO_BP
```

## Standardize outputs for OmicsKit

After GSEA finishes, run:

```bash
Rscript preranked/scripts/02_standardize_gsea_outputs.R
```

This creates OmicsKit-ready TSV files in:

```text
preranked/examples/brca/omicskit_ready/
```

Expected output files:

```text
GSEA_ERpositive_vs_ERnegative_Hallmark.tsv
GSEA_ERpositive_vs_ERnegative_GO_BP.tsv
GSEA_Tumor_vs_Normal_Hallmark.tsv
GSEA_Tumor_vs_Normal_GO_BP.tsv
GSEA_BRCA_all_comparisons_Hallmark_GO_BP.tsv
```

## Copy outputs to OmicsKit

Set your OmicsKit path and run:

```bash
bash preranked/scripts/03_copy_omicskit_ready_outputs.sh ../OmicsKit
```

This copies:

- standardized GSEA TSVs
- RNK files
- RNK metadata

to:

```text
OmicsKit/inst/extdata/brca/gsea_outputs/
```

## Output contract for OmicsKit

Each OmicsKit-ready TSV contains these standardized columns:

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
direction
significant_fdr_0_25
significant_fdr_0_05
source_file
```

These files are intended to be imported by:

```text
OmicsKit/data-raw/brca/05_import_gsea_pipeline_outputs_brca.R
```
