#!/bin/bash

# Author: Daniel Guevara
# dgdiaz011202@gmail.com
# June 23rd, 2024

# Use this script to merge and rename GSEA results data.

# ------------- #
# Define routes #
# ------------- #

main_dir=/path_to_home_directory
output_dir=$main_dir/C2_CGP    

# Iterate over each subdirectory in the main directory
for dir in "$output_dir"/*/; do
  # Extract the comparison and collection from the directory name
  dir_name=$(basename "$dir")
  comparison=$(echo "$dir_name" | grep -oP '(?<=C2_CGP_).*(?=.Gsea)')
  collection="C2_CGP"

  # Define the output file name
  output_file="$output_dir/${collection}_${comparison}_merged.tsv"

  # Initialize a flag to track the header
  header_included=false

  # Find and merge all matching files within the subdirectory
  for file in "$dir"gsea_report_for*.tsv; do
    if [ "$header_included" = false ]; then
      # Include the header for the first file
      cat "$file" >> "$output_file"
      header_included=true
    else
      # Skip the header for subsequent files
      tail -n +2 "$file" >> "$output_file"
    fi
  done

  echo "Merged files from $dir into $output_file"
done
