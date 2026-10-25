#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

# Locate pa3 regardless of where the command is launched.
PA3=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DUCKDB=/mnt/scratch/CS131_jelenag/tools/duckdb-current/duckdb
INPUT=${1:?Usage: bash run_benchmark.sh INPUT_CSV}

if [[ ! -r "$INPUT" || ! -s "$INPUT" ]]; then
    echo "ERROR: Input must be readable and nonempty." >&2
    exit 1
fi
INPUT=$(realpath "$INPUT")

BENCH="$PA3/work/benchmark"
mkdir -p "$BENCH"/{scripts,work,out} "$PA3/logs" "$PA3/out"

# Select the first million records passing the existing team filters.
echo "Preparing benchmark input..."
awk -F',' 'BEGIN { OFS="\t" }
NR == 1 { print $3, $4, $6, $7; next }
$7 > 0 && $3 ~ /^[A-Z][0-9]{4}$/ {
    print $3, $4, $6, $7
    count++
    if (count == 1000000) exit
}' "$INPUT" > "$BENCH/work/analysis_ready.tsv"

ROWS=$(awk 'END { print NR-1 }' "$BENCH/work/analysis_ready.tsv")
if [[ "$ROWS" -ne 1000000 ]]; then
    echo "ERROR: Expected 1000000 qualifying records; found $ROWS." >&2
    exit 1
fi

# Existing analyses use paths relative to a scripts directory.
cd "$BENCH/scripts"

# Parquet conversion is outside the timed analysis runs.
"$DUCKDB" -bail < "$PA3/sql/build_parquet.sql" \
    > "$PA3/logs/benchmark_build_parquet.log" 2>&1

TEXT_BYTES=$(wc -c < ../work/analysis_ready.tsv)
PARQUET_BYTES=$(wc -c < ../work/analysis_ready.parquet)

run_analysis() {
    case "$1" in
        shell)
            bash -e -o pipefail "$PA3/scripts/run_shell_analysis.sh"
            ;;
        text)
            "$DUCKDB" -bail < "$PA3/sql/analysis_text.sql"
            ;;
        parquet)
            "$DUCKDB" -bail < "$PA3/sql/analysis_parquet.sql"
            ;;
    esac
}

# Verify all three paths before timing. This also warms the cache.
COMPARISON="$PA3/logs/benchmark_comparison.txt"
: > "$COMPARISON"

for path in shell text parquet; do
    run_analysis "$path" \
        > "$PA3/logs/benchmark_${path}_check.log" 2>&1
done

diff -u ../out/shell_result.tsv ../out/duckdb_text_result.tsv \
    >> "$COMPARISON"
diff -u ../out/duckdb_text_result.tsv ../out/duckdb_parquet_result.tsv \
    >> "$COMPARISON"

# Check that the verified reference has five columns and data rows.
awk -F'\t' '
    NF != 5 { bad=1 }
    END { exit (bad || NR < 2) }
' ../out/shell_result.tsv

cp ../out/shell_result.tsv ../work/verified_reference.tsv
echo "Initial three-way comparison passed." >> "$COMPARISON"

RESULTS="$BENCH/out/benchmark.tsv"
printf 'implementation\tstorage_format\trun\tinput_rows\tinput_bytes\treal_seconds\tresult_verified\n' \
    > "$RESULTS"

TIMEFORMAT='%R'

for path in shell text parquet; do
    case "$path" in
        shell)
            implementation=shell
            format=text
            bytes=$TEXT_BYTES
            result=../out/shell_result.tsv
            ;;
        text)
            implementation=duckdb
            format=text
            bytes=$TEXT_BYTES
            result=../out/duckdb_text_result.tsv
            ;;
        parquet)
            implementation=duckdb
            format=parquet
            bytes=$PARQUET_BYTES
            result=../out/duckdb_parquet_result.tsv
            ;;
    esac

    for run in 1 2 3; do
        echo "Timing $implementation/$format, run $run of 3..."
        log="$PA3/logs/benchmark_${path}_${run}.log"
        timing="$BENCH/work/${path}_${run}.seconds"

        { time run_analysis "$path" > "$log" 2>&1; } 2> "$timing"
        seconds=$(cat "$timing")

        # Verification happens outside the timed section.
        if ! diff -u ../work/verified_reference.tsv "$result" \
            >> "$COMPARISON"; then
            echo "ERROR: $path run $run differs from the reference." >&2
            exit 1
        fi

        printf '%s\t%s\t%s\t%s\t%s\t%s\ttrue\n' \
            "$implementation" "$format" "$run" \
            "$ROWS" "$bytes" "$seconds" >> "$RESULTS"

        echo "$path run $run: verified" >> "$COMPARISON"
    done
done

cp "$RESULTS" "$PA3/out/benchmark.tsv"
echo "All nine runs completed and verified."
cat "$PA3/out/benchmark.tsv"
