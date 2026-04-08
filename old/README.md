# GSEA Pipeline


This guide provides an overview of the various scripts used in the Gene Set Enrichment Analysis (GSEA) pipeline. These scripts facilitate preprocessing, merging, checking, and running GSEA analyses, as well as handling differential expression data.

```plaintext
1. final_genes.sh
   This script extracts gene symbols from .grp files and appends them to a final output file.

   Example usage:
   ./final_genes.sh

2. GSEA_count.sh
   This script checks that all comparisons include the same number of gene sets by counting the lines in the GSEA result files.

   Example usage:
   ./GSEA_count.sh

3. GSEA_merge.sh
   This script merges and renames GSEA result data files, ensuring a consistent header is included only once.

   Example usage:
   ./GSEA_merge.sh

4. GSEA_check.sh
   This script checks that all merged files contain the same sets by comparing the first column of each file.

   Example usage:
   ./GSEA_check.sh

5. GSEA_script.sh
   This script is intended for multiple parallel GSEA runs. It defines the parameters and directories required for the analysis.

   Example usage:
   ./GSEA_script.sh

6. GSEA_all.sh
   This script merges all GSEA result data into a single file, ensuring that all files share the same sets.

   Example usage:
   ./GSEA_all.sh

7. GSEA_script_test.sh
   This script is similar to `GSEA_script.sh` but includes multiple comparisons for testing purposes.

   Example usage:
   ./GSEA_script_test.sh

8. md5compare.py
   This script compares MD5 checksums to ensure file integrity.

   Example usage:
   python md5compare.py file1 file2

9. retrieveMSigDB.py
   This script retrieves gene sets from the MSigDB database.

   Example usage:
   python retrieveMSigDB.py -o output_directory

```

Summary
This README provides a comprehensive guide to the scripts used in the GSEA pipeline, detailing their purposes and usage. Each script plays a critical role in ensuring the accuracy and efficiency of the GSEA process.
