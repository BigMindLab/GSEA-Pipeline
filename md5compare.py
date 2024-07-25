import pandas as pd
import os
import argparse

def merge_md5_fastq_files(folder_path):
    """Reads and merges multiple text files with MD5 and FASTQ file names."""
    dfs = []
    
    for filename in os.listdir(folder_path):
        if filename.endswith('.txt'):
            file_path = os.path.join(folder_path, filename)
            df = pd.read_csv(file_path, sep='\t', header=None, names=['MD5', 'FASTQ'])
            dfs.append(df)
    
    merged_df = pd.concat(dfs, ignore_index=True)
    return merged_df

def read_md5sum_file(md5sum_file_path):
    """Reads the MD5 checksum file into a DataFrame."""
    df = pd.read_csv(md5sum_file_path, sep='\t', header=None, names=['MD5', 'FASTQ'])
    return df

def compare_dataframes(merged_df, md5sum_df):
    """Compares two DataFrames and returns differences."""
    merged_df_sorted = merged_df.sort_values(by=['MD5', 'FASTQ']).reset_index(drop=True)
    md5sum_df_sorted = md5sum_df.sort_values(by=['MD5', 'FASTQ']).reset_index(drop=True)
    
    comparison_result = merged_df_sorted.compare(md5sum_df_sorted)
    return comparison_result

def main():
    parser = argparse.ArgumentParser(description='Merge MD5/FASTQ files and compare with MD5SUM file.')
    parser.add_argument('folder_path', type=str, help='Path to the folder containing text files with MD5 and FASTQ file names.')
    parser.add_argument('md5sum_file_path', type=str, help='Path to the MD5SUM file.')

    args = parser.parse_args()

    merged_df = merge_md5_fastq_files(args.folder_path)
    md5sum_df = read_md5sum_file(args.md5sum_file_path)
    comparison_result = compare_dataframes(merged_df, md5sum_df)

    print("Merged DataFrame:")
    print(merged_df)
    print("\nMD5SUM DataFrame:")
    print(md5sum_df)
    print("\nComparison Result:")
    print(comparison_result)

if __name__ == '__main__':
    main()