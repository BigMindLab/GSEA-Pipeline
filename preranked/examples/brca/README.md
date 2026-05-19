# TCGA-BRCA GSEAPreranked example

This example is designed to use TCGA-BRCA RNA-seq differential expression results generated in OmicsKit.

## Comparisons

```text
ERpositive_vs_ERnegative
Tumor_vs_Normal
```

## Input ranked lists

Place these files in:

```text
preranked/examples/brca/rnk/
```

```text
BRCA_ERpositive_vs_ERnegative.rnk
BRCA_Tumor_vs_Normal.rnk
```

Each `.rnk` file should have two tab-separated columns and no header:

```text
GENE_SYMBOL    ranking_metric
```

Example:

```text
ESR1    25.391
GATA3   22.114
XBP1    20.007
```

The recommended ranking metric is the limma moderated `t` statistic.

## Gene sets

Place your GMT files in:

```text
preranked/examples/brca/input/gmt/
```

Example names:

```text
h.all.v2025.1.Hs.symbols.gmt
c5.go.bp.v2025.1.Hs.symbols.gmt
```

## Final OmicsKit-ready outputs

After running the workflow, this folder should contain:

```text
preranked/examples/brca/omicskit_ready/
├── GSEA_ERpositive_vs_ERnegative_Hallmark.tsv
├── GSEA_ERpositive_vs_ERnegative_GO_BP.tsv
├── GSEA_Tumor_vs_Normal_Hallmark.tsv
├── GSEA_Tumor_vs_Normal_GO_BP.tsv
└── GSEA_BRCA_all_comparisons_Hallmark_GO_BP.tsv
```
