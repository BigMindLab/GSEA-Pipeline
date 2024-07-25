#!/bin/bash

# Define the output file
output_file="final_genes"

# Clear the output file if it already exists
> "$output_file"

# Iterate over each .grp file in the directory
for file in *.grp; do
    # Check if the file exists
    if [[ -f "$file" ]]; then
        # Extract the gene symbols, skipping the first two lines
        tail -n +3 "$file" >> "$output_file"
    fi
done

echo "All gene symbols have been appended to $output_file"
