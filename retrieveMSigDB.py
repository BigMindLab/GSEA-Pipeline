import os
import requests

# Define the base URL for downloading gene set .grp files
base_url = "https://www.gsea-msigdb.org/gsea/msigdb/human/download_geneset.jsp?geneSetName={}&fileType=grp"

# List of gene sets you want to download
gene_sets = [
	"GOCC_ACTIN_FILAMENT",
	"GOCC_DYNEIN_COMPLEX",
	"GENE_SET_NAME" #Add here more gene sets of interest
]

# Define the output directory
output_directory = "GRPs"

# Function to download and save a gene set .grp file
def download_gene_set(gene_set_name):
    url = base_url.format(gene_set_name)
    response = requests.get(url)
    if response.status_code == 200:
        file_path = os.path.join(output_directory, f"{gene_set_name}.grp")
        with open(file_path, 'wb') as file:
            file.write(response.content)
        print(f"Downloaded: {gene_set_name}")
    else:
        print(f"Failed to download: {gene_set_name} - Status code: {response.status_code}")

# Iterate over the list of gene sets and download each
for gene_set in gene_sets:
    download_gene_set(gene_set)

print("All gene sets have been downloaded.")
