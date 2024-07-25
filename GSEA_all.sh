#!/bin/bash

# Author: Daniel Guevara
# dgdiaz011202@gmail.com
# June 23rd, 2024

# Use this script to merge all GSEA result data.

# ------------- #
# Define routes #
# ------------- #

main_dir=/path_to_home_directory
output_dir=$main_dir/C2_CGP    
final_output_file=$output_dir/C2_CGP_all.tsv

# Temporary file to store the first set of names
temp_file=$(mktemp)

# Flag to track if this is the first file
first_file=true

# Iterate over each merged file in the output directory
for file in "$output_dir"/*.tsv; do
  # Extract the NAME column (assuming it's the first column) and sort the names
  cut -f1 "$file" | sort > "$temp_file"_new

  if [ "$first_file" = true ]; then
    # Copy the names from the first file to the temp_file
    mv "$temp_file"_new "$temp_file"
    first_file=false
  else
    # Compare the current file's names with the stored names
    if ! cmp -s "$temp_file" "$temp_file"_new; then
      echo "The file $file does not share the same sets (values in the column NAME) as the others."
      rm "$temp_file" "$temp_file"_new
      exit 1
    fi
    # Clean up the temporary comparison file
    rm "$temp_file"_new
  fi
done

echo "All files share the same sets (values in the column NAME)."
rm "$temp_file"

# Add a column with the comparison name to each file and merge them into the final output file
first_merge=true

for file in "$output_dir"/*.tsv; do
  # Extract the comparison name from the filename
  filename=$(basename "$file")
  comparison=$(echo "$filename" | grep -oP '(?<=C2_CGP_).*(?=_merged.tsv)')

  # Add a column with the comparison name
  awk -v comparison="$comparison" 'BEGIN {OFS="\t"} NR==1 {print $0, "Comparison"} NR>1 {print $0, comparison}' "$file" > "${file%.tsv}_with_comparison.tsv"

  # Merge the files
  if [ "$first_merge" = true ]; then
    cat "${file%.tsv}_with_comparison.tsv" > "$final_output_file"
    first_merge=false
  else
    # Skip the header line for subsequent files
    tail -n +2 "${file%.tsv}_with_comparison.tsv" >> "$final_output_file"
  fi

  # Clean up the temporary files with the comparison column
  rm "${file%.tsv}_with_comparison.tsv"
done

echo "Merged all files into $final_output_file"
