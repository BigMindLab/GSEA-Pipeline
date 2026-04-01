#!/bin/bash

# Author: Daniel Guevara
# dgdiaz011202@gmail.com
# June 23rd, 2024

# This script is intended to be used for multiple parallel GSEA runs.
# Check gsea-cli.sh script for memory parameters.

# ------------- #
# Define routes #
# ------------- #
working_dir=/path_to_home_directory
expression_data=$working_dir/expression_data_CCC.txt
phenotype_info=$working_dir/phenotype_CCC.cls
matrix_dir=$working_dir/Human_Sets
chip_annotations=$working_dir/Human_Annotations
output_dir=$working_dir/C2_CGP

# ------------------ #
# Example for C2_CGP #
# ------------------ #
# Indications:
# - Append comparison of interest to $phenotype_info
# - Download GMX/GMT files from all collections and store them in $matrix_dir. Also include internal control file if needed.
# - nperm: Number of permutation set to 10000. Test iniatilly with lower values.
# - permute: Permuation type set to gene_set if study's phenotypes have less than 10 samples. Default: phenotype.
# - metric: Metric for ranking genes. Use log2_Ratio_of_Classes when at least one of the comparison's phenotypes indicates less than 3 samples.

comparisons=('A_versus_B')
labels=('C2_CGP_A_B')

for i in "${!comparisons[@]}"; do
  comparison=${comparisons[$i]}
  label=${labels[$i]}

  echo "Running GSEA for comparison: $comparison"

  gsea-cli.sh GSEA -res $expression_data \
   -cls $phenotype_info"#${comparison}" \
   -gmx $matrix_dir/c2.cgp.v2023.2.Hs.symbols.gmt \
   -collapse Collapse \
   -mode Max_probe \
   -norm meandiv \
   -nperm 10000 \
   -permute gene_set \
   -rnd_seed timestamp \
   -rnd_type no_balance \
   -scoring_scheme weighted \
   -rpt_label ${label} \
   -metric log2_Ratio_of_Classes \
   -sort real \
   -order descending \
   -chip $chip_annotations/Human_Ensembl_Gene_ID_MSigDB.v2023.2.Hs.chip \
   -create_gcts false \
   -create_svgs false \
   -include_only_symbols true \
   -make_sets true \
   -median false \
   -num 100 \
   -plot_top_x 50 \
   -save_rnd_lists false \
   -set_max 500 -set_min 15 \
   -zip_report false \
   -out $output_dir &
done

# Wait for all background jobs to finish
wait

echo "All GSEA analyses completed."
