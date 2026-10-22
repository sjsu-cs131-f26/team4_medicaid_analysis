#!/usr/bin/env bash
#set -euo pipefail

#Parameters
dataset_file="${1:-../data/sample/sample_1000.csv}"

#Parameter validation
if [[ ! -f "$dataset_file" || ! -r "$dataset_file" || ! -s "$dataset_file" ]]; then
	echo -e "ERROR: Input file is missing, unreadable, or empty" >&2
	exit 1
fi

#Global variables
mkdir -p ../work ../logs ../out
output_file="../work/analysis_ready.tsv"
log_file="../logs/prepare_data.log"
DUCKDB="/mnt/scratch/CS131_jelenag/tools/duckdb-current/duckdb"





#---------------------------
#TASK 2: Readying data-set
#---------------------------

echo -e "Filtering dataset..." | tee "$log_file"

# Filters out unncessary fields, entries with $0 paid out, and entries with invalid HCPCS codes
cut -d',' -f3,4,6,7 "$dataset_file" | \
sed 's/,/\t/g' | \
awk -F'\t' '($4 > 0 || NR == 1) {print $0}' | \
awk -F'\t' '(NR == 1 || $1 ~ /^[A-Z][0-9]{4}$/) {print $0}' > "$output_file"

echo -e "..Data filtered\n" | tee -a "$log_file"

# Ensures each row has exactly 4 fields
echo "Validating records..." | tee -a "$log_file"
if ! awk -F'\t' '(NF != 4) { exit 1 }' "$output_file"; then
	echo -e "ERROR: Incorrect field count" | tee -a "$log_file"  >&2
	exit 2
fi
echo -e "...Records Validated:" | tee -a "$log_file"
echo -e "$(wc -l < "$output_file") records kept out of $(wc -l < "$dataset_file")\n" | tee -a "$log_file"

#---------------------------
#TASK 4: Three way analysis
#---------------------------

echo -e "Running shell analysis..." | tee -a "$log_file"
./run_shell_analysis.sh
echo -e "...Done" | tee -a "$log_file"

echo -e "Running duckdb analysis..." | tee -a "$log_file"
$DUCKDB ../work/project.duckdb < ../sql/analysis_text.sql > ../logs/duckdb_text.log 2>&1
echo -e "...Done" | tee -a "$log_file"

echo -e "Running duckdb parquet analysis..." | tee -a "$log_file"
$DUCKDB ../work/project.duckdb < ../sql/build_parquet.sql > ../logs/build_parquet.log 2>&1
$DUCKDB ../work/project.duckdb < ../sql/analysis_parquet.sql > ../logs/duckdb_parquet.log 2>&1
echo -e "...Done" | tee -a "$log_file"
