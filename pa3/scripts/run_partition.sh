#!/usr/bin/env bash

set -u
set -o pipefail

PARTITION_PATH="${1:-}"
DUCKDB="/mnt/scratch/CS131_jelenag/tools/duckdb-current/duckdb"
PROJECT_DIR="/mnt/scratch/CS131_jelenag/projects/team04_sec02_fall2026/team4_medicaid_analysis/pa3"

if [[ -z "$PARTITION_PATH" ]]; then
    echo "Usage: $0 PARTITION_PATH" >&2
    exit 1
fi

if [[ ! -r "$PARTITION_PATH" ]]; then
    echo "Partition is not readable: $PARTITION_PATH" >&2
    exit 1
fi

PARTITION_ID="$(basename "$PARTITION_PATH" .parquet)"
OUTPUT_PATH="$PROJECT_DIR/out/partitions/${PARTITION_ID}_result.tsv"

mkdir -p "$PROJECT_DIR/out/partitions"

"$DUCKDB" "$PROJECT_DIR/work/project.duckdb" -c "
COPY (
    SELECT
        HCPCS_CODE,
        CLAIM_FROM_MONTH,
        SUM(TOTAL_PAID) AS TOTAL_PAID,
        SUM(TOTAL_CLAIM_LINES) AS TOTAL_CLAIM_LINES
    FROM read_parquet('$PARTITION_PATH')
    GROUP BY HCPCS_CODE, CLAIM_FROM_MONTH
    ORDER BY HCPCS_CODE, CLAIM_FROM_MONTH
)
TO '$OUTPUT_PATH'
(HEADER, DELIMITER '\t');
"

if [[ ! -s "$OUTPUT_PATH" ]]; then
    echo "Output was not created: $OUTPUT_PATH" >&2
    exit 1
fi

echo "Created: $OUTPUT_PATH"
