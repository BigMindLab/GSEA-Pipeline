#!/bin/bash

# Author: Daniel Guevara
# dgdiaz011202@gmail.com
# June 23rd, 2024

# Use this script to check that all the comparisons included the same amount of gene sets.

# ------------- #
# Define routes #
# ------------- #

directory=/path_to_home_directory
collection=$directory/C2_CGP

# Iterate over each subdirectory in the main directory
for dir in "$collection"/*/; do
  # Count the total number of lines in all matching files within the subdirectory
  count=$(find "$dir" -name 'gsea_report_for*.tsv' -exec cat {} + | wc -l)
  
  # Subtract 2 due to first row headers for each file
  final_count=$((count - 2))
  
  # Print the subdirectory name and the final count
  echo "Directory: $(basename "$dir"), Number of sets: $final_count"
done
