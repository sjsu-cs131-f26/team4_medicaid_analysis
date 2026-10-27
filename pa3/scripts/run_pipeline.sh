#!/usr/bin/env bash
set -euo pipefail


input_param="${1:-../data/sample/sample.tsv}"

if [[ "$input_param" = /* ]]; then
	dataset_file="$input_param"
else
	dataset_file="$(pwd)/$input_param"
fi

cd "$(dirname "$(readlink -f "${BASH_SOURCE}")")"


#Parameter validation
if [[ ! -f "$dataset_file" || ! -r "$dataset_file" || ! -s "$dataset_file" ]]; then
	echo -e "ERROR: Input file is missing, unreadable, or empty" >&2
	exit 1
fi

#Global variables
mkdir -p ../work ../logs ../out
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
awk -F'\t' '(NR == 1 || $1 ~ /^[A-Z][0-9]{4}$/) {print $0}' > "../work/analysis_ready.tsv"

echo -e "..Data filtered\n" | tee -a "$log_file"

# Ensures each row has exactly 4 fields
echo "Validating records..." | tee -a "$log_file"
if ! awk -F'\t' '(NF != 4) { exit 1 }' "../work/analysis_ready.tsv"; then
	echo -e "ERROR: Incorrect field count" | tee -a "$log_file"  >&2
	exit 2
fi
echo -e "...Records Validated:" | tee -a "$log_file"
echo -e "$(wc -l < ../work/analysis_ready.tsv) records kept out of $(wc -l < "$dataset_file")\n" | tee -a "$log_file"

#---------------------------
#TASK 4: Three way analysis
#---------------------------

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

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

# Verify each sample is nonempty
if [[ ! -s "../out/shell_result.tsv" || ! -s "../out/duckdb_text_result.tsv" || ! -s "../out/duckdb_parquet_result.tsv" ]]; then
        echo -e "ERROR: Three way analysis generated one or more empty files" >&2
        exit 3
fi

#---------------------------
#TASK 5: diff verification
#---------------------------
diff_threshold=5

echo -e "\nshell result VS DuckDB text result:" | tee -a "$log_file"
diff_count=$(diff -y --suppress-common-lines ../out/shell_result.tsv ../out/duckdb_text_result.tsv | wc -l) || true
echo -e "$diff_count differing lines found" | tee -a "$log_file"
if (( diff_count >= diff_threshold )); then
	echo -e "ERROR: diff_count reached threshold" | tee -a "$log_file"  >&2
	exit 4
fi

echo -e "\nDuckDB text result VS DuckDB Parquet result:" | tee -a "$log_file"
diff_count=$(diff -y --suppress-common-lines ../out/duckdb_text_result.tsv ../out/duckdb_parquet_result.tsv | wc -l) || true
echo -e "$diff_count differing lines found" | tee -a "$log_file"
if (( diff_count >= diff_threshold )); then
        echo -e "ERROR: diff_count reached threshold" | tee -a "$log_file"  >&2
        exit 4
fi

#----------------------------------------
#TASK 7: Build one complete entry script
#----------------------------------------

# Since all outputs generally result in the same thing, we choose one to copy as the final result.
echo -e "\nGenerating final analysis..."
cp ../out/duckdb_text_result.tsv ../out/final_analysis.tsv
echo -e "...Done"

echo -e "\nScript successfully completed!\n"
