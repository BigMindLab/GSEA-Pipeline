#!/bin/bash

################################################################################
# GSEA Parallel Execution Script (Test Version)
################################################################################
# 
# Author: Daniel Guevara & Daniel Garbozo
# Date: June 23rd, 2024 (Updated February 2025)
# Email: dgdiaz011202@gmail.com, dan.garbozo.urp@gmail.com
#
# Description:
#   This script executes multiple GSEA analyses in parallel. It is designed for
#   testing and debugging GSEA pipelines before running large-scale analyses.
#   The script processes multiple gene set collections and comparisons.
#
# Requirements:
#   - GSEA installed and gsea-cli.sh in PATH
#   - Java installed (GSEA requirement)
#   - Gene expression data in tab-separated format
#   - Phenotype/class file (.cls) with phenotype definitions
#   - Gene set matrix files (.gmt) from MSigDB
#   - Annotation files (.chip) for gene ID conversion
#
# GSEA Documentation:
#   See: https://docs.gsea-msigdb.org/#GSEA/GSEA_User_Guide/Running_GSEA_from_the_Command_Line
#   Key parameters explained in official documentation
#
# Usage:
#   1. Edit the path configuration below (section "Define Routes")
#   2. Adjust comparisons and labels arrays as needed
#   3. Modify GSEA parameters in the gsea-cli.sh call if necessary
#   4. Run: ./GSEA_script_test.sh
#
# Output:
#   Results saved in $output_dir with subdirectories for each comparison.
#   Check for "GSEA analysis completed" message at the end.
#
################################################################################

# ------------- #
# Define Routes #
# ------------- #
# IMPORTANT: Customize these paths for your system and data

# Base working directory (all GSEA data should be organized here)
working_dir="/media/david/bm2/Requena_Chagas_CCC/GSEA_v2/"

# Input files
expression_data="${working_dir}/GSEA_expression_data.txt"
phenotype_info="${working_dir}/phenotype_requena_CCC.cls"

# Gene set and annotation directories
matrix_dir="${working_dir}/Human_Sets"
chip_annotations="${working_dir}/Human_Annotations"

# Output directory (results will be saved here)
output_dir="${working_dir}/C3_TFTLEGACY"

# Verify that all input files exist
if [ ! -f "$expression_data" ]; then
    echo "ERROR: Expression data file not found: $expression_data"
    exit 1
fi

if [ ! -f "$phenotype_info" ]; then
    echo "ERROR: Phenotype file not found: $phenotype_info"
    exit 1
fi

if [ ! -d "$matrix_dir" ]; then
    echo "ERROR: Gene set directory not found: $matrix_dir"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# ----------------------------- #
# Define Comparisons & Parameters #
# ----------------------------- #
# Comparisons: Format as "Group1_vs_Group2" (must match phenotype file)
# Labels: Output directory names for each comparison

comparisons=('Ap_versus_An' 'Bp_versus_An' 'Bp_versus_Ap' 'Bp_versus_Bn' 'Bn_versus_An')
labels=('C3_TFTLEGACY_Ap_An' 'C3_TFTLEGACY_Bp_An' 'C3_TFTLEGACY_Bp_Ap' 'C3_TFTLEGACY_Bp_Bn' 'C3_TFTLEGACY_Bn_An')

# -------------------------------- #
# GSEA Parameter Documentation     #
# -------------------------------- #
# nperm:       Number of permutations (10,000 recommended for publication)
# permute:     'gene_set' if any phenotype has <10 samples; 'phenotype' otherwise
# metric:      'Signal2Noise' for normal; 'log2_Ratio_of_Classes' for small samples
# set_max:     Maximum gene set size (500 typical)
# set_min:     Minimum gene set size (15 typical)
# rnd_seed:    Random seed for reproducibility
# norm:        Normalization method ('meandiv' recommended)
# collapse:    'No_Collapse' typically for symbol-based annotations
#
# For detailed parameter descriptions:
# https://docs.gsea-msigdb.org/#GSEA/GSEA_User_Guide/Running_GSEA_from_the_Command_Line

# --------- #
# Run GSEA  #
# --------- #

echo "Starting GSEA analysis..."
start_time=$(date)
echo "Start time: $start_time"
echo "---"

# Loop through each comparison
for i in "${!comparisons[@]}"; do
  comparison=${comparisons[$i]}
  label=${labels[$i]}

  echo "Running GSEA for comparison: $comparison"
  echo "  Output label: $label"

  # Run GSEA in background (parallel processing)
  gsea-cli.sh GSEA \
   -res "$expression_data" \
   -cls "${phenotype_info}#${comparison}" \
   -gmx "${matrix_dir}/c3.tft.tft_legacy.v2023.2.Hs.symbols.gmt" \
   -collapse No_Collapse \
   -mode Max_probe \
   -norm meandiv \
   -nperm 10000 \
   -permute gene_set \
   -rnd_seed 149 \
   -rnd_type no_balance \
   -scoring_scheme classic \
   -rpt_label "${label}" \
   -metric Signal2Noise \
   -sort abs \
   -order descending \
   -chip "${chip_annotations}/Human_Ensembl_Gene_ID_MSigDB.v2023.2.Hs.chip" \
   -create_gcts false \
   -create_svgs false \
   -include_only_symbols true \
   -make_sets true \
   -median false \
   -num 100 \
   -plot_top_x 100 \
   -save_rnd_lists false \
   -set_max 500 \
   -set_min 15 \
   -zip_report false \
   -out "$output_dir" &
done

# ----------------------- #
# Wait for All Jobs Done #
# ----------------------- #

echo "Waiting for all GSEA jobs to complete..."
wait

# Report completion
end_time=$(date)
echo "---"
echo "GSEA analysis started at: $start_time"
echo "GSEA analysis completed at: $end_time"
echo "All analyses finished successfully."
echo "Results saved to: $output_dir"
