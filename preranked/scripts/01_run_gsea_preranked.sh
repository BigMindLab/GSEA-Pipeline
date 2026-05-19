#!/usr/bin/env bash
set -euo pipefail

################################################################################
# GSEAPreranked Batch Execution Script
#
# Runs GSEAPreranked for multiple comparisons and gene-set collections using
# a TSV configuration file.
#
# Usage:
#   bash preranked/scripts/01_run_gsea_preranked.sh
#
# Optional environment variables:
#   GSEA_CLI=/path/to/gsea-cli.sh
#   N_PERM=1000
#   SET_MIN=15
#   SET_MAX=500
#   SEED=2025
#   SCORING_SCHEME=weighted
#   MAX_JOBS=4
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRERANKED_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${PRERANKED_DIR}/.." && pwd)"

CONFIG_FILE="${PRERANKED_DIR}/config/brca_preranked_config.tsv"
EXAMPLE_DIR="${PRERANKED_DIR}/examples/brca"
RNK_DIR="${EXAMPLE_DIR}/rnk"
GMT_DIR="${EXAMPLE_DIR}/input/gmt"
RAW_GSEA_DIR="${EXAMPLE_DIR}/raw_gsea"

GSEA_CLI="${GSEA_CLI:-gsea-cli.sh}"

N_PERM="${N_PERM:-1000}"
SET_MIN="${SET_MIN:-15}"
SET_MAX="${SET_MAX:-500}"
SEED="${SEED:-2025}"
SCORING_SCHEME="${SCORING_SCHEME:-weighted}"
PLOT_TOP_X="${PLOT_TOP_X:-20}"
MAX_JOBS="${MAX_JOBS:-4}"

mkdir -p "${RAW_GSEA_DIR}"

require_file() {
  local file="$1"
  local label="$2"
  if [[ ! -f "${file}" ]]; then
    echo "ERROR: Missing ${label}: ${file}" >&2
    exit 1
  fi
}

find_gmt() {
  local pattern="$1"
  local matches=()
  shopt -s nullglob
  matches=("${GMT_DIR}"/${pattern})
  shopt -u nullglob

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo "ERROR: No GMT file matched pattern '${pattern}' in ${GMT_DIR}" >&2
    exit 1
  fi

  if [[ ${#matches[@]} -gt 1 ]]; then
    echo "ERROR: Multiple GMT files matched pattern '${pattern}' in ${GMT_DIR}" >&2
    printf '  %s\n' "${matches[@]}" >&2
    exit 1
  fi

  echo "${matches[0]}"
}

wait_for_slot() {
  while [[ "$(jobs -rp | wc -l | tr -d ' ')" -ge "${MAX_JOBS}" ]]; do
    sleep 2
  done
}

require_file "${CONFIG_FILE}" "configuration TSV"

echo "GSEAPreranked batch run"
echo "  repo root:       ${REPO_ROOT}"
echo "  config:          ${CONFIG_FILE}"
echo "  rnk dir:         ${RNK_DIR}"
echo "  gmt dir:         ${GMT_DIR}"
echo "  output dir:      ${RAW_GSEA_DIR}"
echo "  gsea cli:        ${GSEA_CLI}"
echo "  nperm:           ${N_PERM}"
echo "  set_min/set_max: ${SET_MIN}/${SET_MAX}"
echo "  max jobs:        ${MAX_JOBS}"
echo

start_time="$(date)"

tail -n +2 "${CONFIG_FILE}" | while IFS=$'\t' read -r comparison rnk_file collection gmt_pattern output_label; do
  [[ -z "${comparison}" ]] && continue

  rnk_path="${RNK_DIR}/${rnk_file}"
  gmt_path="$(find_gmt "${gmt_pattern}")"
  out_dir="${RAW_GSEA_DIR}/${comparison}/${collection}"

  require_file "${rnk_path}" "RNK file"

  mkdir -p "${out_dir}"

  echo "Launching:"
  echo "  comparison: ${comparison}"
  echo "  collection: ${collection}"
  echo "  rnk:        ${rnk_path}"
  echo "  gmt:        ${gmt_path}"
  echo "  label:      ${output_label}"
  echo "  out:        ${out_dir}"
  echo

  wait_for_slot

  "${GSEA_CLI}" GSEAPreranked \
    -rnk "${rnk_path}" \
    -gmx "${gmt_path}" \
    -collapse No_Collapse \
    -nperm "${N_PERM}" \
    -scoring_scheme "${SCORING_SCHEME}" \
    -rpt_label "${output_label}" \
    -rnd_seed "${SEED}" \
    -set_min "${SET_MIN}" \
    -set_max "${SET_MAX}" \
    -plot_top_x "${PLOT_TOP_X}" \
    -out "${out_dir}" \
    > "${out_dir}/${output_label}.log" 2>&1 &

done

echo "Waiting for all GSEAPreranked jobs to finish..."
wait

end_time="$(date)"
echo
echo "Started:   ${start_time}"
echo "Completed: ${end_time}"
echo "All GSEAPreranked jobs completed."
echo "Raw outputs: ${RAW_GSEA_DIR}"
