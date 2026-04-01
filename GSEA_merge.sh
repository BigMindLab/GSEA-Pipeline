#!/bin/bash

################################################################################
# GSEA Results Merging Script
################################################################################
#
# Author: Daniel Garbozo & Daniel Guevara
# Date: February 20, 2025
# Email: dan.garbozo.urp@gmail.com, dgdiaz011202@gmail.com
#
# Description:
#   This script merges multiple GSEA result files from different collections and
#   comparisons. It:
#   - Processes results organized by gene set collection
#   - Merges positive and negative enrichment results
#   - Handles GSEA's timestamp-based directory naming
#   - Ensures headers are included only once in merged files
#
# Input Structure:
#   Expected directory organization:
#   
#   main_dir/
#   ├── Collection1_Name/
#   │   ├── Comparison1_Timestamp/
#   │   │   ├── gsea_report_for_POSITIVE.tsv
#   │   │   └── gsea_report_for_NEGATIVE.tsv
#   │   ├── Comparison2_Timestamp/
#   │   │   ├── gsea_report_for_POSITIVE.tsv
#   │   │   └── gsea_report_for_NEGATIVE.tsv
#   │   └── ...
#   ├── Collection2_Name/
#   │   ├── Comparison1_Timestamp/
#   │   │   ├── gsea_report_for_POSITIVE.tsv
#   │   │   └── gsea_report_for_NEGATIVE.tsv
#   │   └── ...
#   └── ...
#
# Output Structure:
#   destination_dir/
#   ├── Collection1_Comparison1_merged.tsv
#   ├── Collection1_Comparison2_merged.tsv
#   ├── Collection2_Comparison1_merged.tsv
#   └── ...
#
# Features:
#   - Automatic extraction of collection and comparison names
#   - Removal of GSEA-specific timestamps and formatting
#   - Prevention of duplicate headers in merged output
#   - Graceful handling of missing files
#   - Progress reporting during processing
#
# Usage:
#   1. Edit path configuration below (section "Define Routes")
#   2. Ensure input directory structure matches expected format
#   3. Run: ./GSEA_merge_v2.sh
#   4. Check destination_dir for merged TSV files
#
# Notes:
#   - Requires GSEA output in standard format (gsea_report_for_*.tsv files)
#   - Timestamps are automatically cleaned from directory names
#   - Works with any number of collections and comparisons
#   - Creates destination directory if it doesn't exist
#
################################################################################

# ------------- #
# Define Routes #
# ------------- #
# IMPORTANT: Customize these paths for your system

# Main directory containing GSEA results organized by collection
# Each subdirectory should be a collection name (e.g., c1, c2.cgp, c3, c5, etc.)
main_dir="/media/david/bm2/Platelets_TB/GSEA/Collections"

# Directory where merged output files will be saved
destination_dir="/media/david/bm2/Platelets_TB/GSEA/all_tsv"

# ------------------- #
# Validation & Setup  #
# ------------------- #

echo "GSEA Results Merging Script"
echo "============================"
echo "Input directory: $main_dir"
echo "Output directory: $destination_dir"
echo ""

# Check if input directory exists
if [ ! -d "$main_dir" ]; then
    echo "ERROR: Input directory not found: $main_dir"
    exit 1
fi

# Create the destination directory if it doesn't exist
mkdir -p "$destination_dir"

if [ $? -ne 0 ]; then
    echo "ERROR: Could not create destination directory: $destination_dir"
    exit 1
fi

# -------------------- #
# Processing Function  #
# -------------------- #

total_files=0
total_collections=0

# Iterate over each subdirectory (collection) in the main directory
for collection_dir in "$main_dir"/*/; do
  # Skip if not a directory
  if [ ! -d "$collection_dir" ]; then
    continue
  fi

  collection_name=$(basename "$collection_dir")  # e.g., c1, c2.cgp, c5, etc.
  echo "Processing collection: $collection_name"
  ((total_collections++))

  # Iterate over each comparison subdirectory within the collection
  for comparison_dir in "${collection_dir}"*/; do
    # Skip if not a directory
    if [ ! -d "$comparison_dir" ]; then
      continue
    fi

    raw_comparison_name=$(basename "$comparison_dir")
    # Example format: c1_TB_Control.Gsea.1740033310298
    # Goal: Extract "TB_Control" from this string

    # Step 1: Remove the collection prefix (e.g., "c1_")
    comparison_name_clean=$(echo "$raw_comparison_name" \
      | sed "s/^${collection_name}_//" \
      | sed 's/\.Gsea\.[0-9]\+//')
    # Result: "TB_Control"

    echo "  → Processing comparison: $raw_comparison_name"
    echo "     Cleaned name: $comparison_name_clean"

    # Define the output merged file path
    # Format: collection_comparison_merged.tsv
    output_file="${destination_dir}/${collection_name}_${comparison_name_clean}_merged.tsv"

    # Initialize flag to track if header has been added
    header_included=false

    # Find and merge all gsea_report_for*.tsv files in the comparison directory
    # This includes both POSITIVE and NEGATIVE results
    for file in "${comparison_dir}"gsea_report_for*.tsv; do
      
      # Check if file exists (in case no matches found)
      if [ -f "$file" ]; then
        
        if [ "$header_included" = false ]; then
          # First file: include header
          cat "$file" >> "$output_file"
          header_included=true
          echo "      ✓ Added header from: $(basename $file)"
        else
          # Subsequent files: skip header (tail -n +2)
          tail -n +2 "$file" >> "$output_file"
          echo "      ✓ Appended: $(basename $file)"
        fi
        
        ((total_files++))
      fi
    done

    # Verify that merged file was created and has content
    if [ -f "$output_file" ]; then
      line_count=$(wc -l < "$output_file")
      echo "    ✓ Merged file created: $output_file ($line_count lines)"
    else
      echo "    ⚠ WARNING: No matching TSV files found in $comparison_dir"
    fi
  done
done

# --------
# Summary
# --------

echo ""
echo "============================"
echo "Processing Complete"
echo "============================"
echo "Collections processed: $total_collections"
echo "Files merged: $total_files"
echo "Output directory: $destination_dir"
echo ""
echo "All GSEA results have been merged successfully."
echo "Use merged files in $destination_dir for downstream analysis."
