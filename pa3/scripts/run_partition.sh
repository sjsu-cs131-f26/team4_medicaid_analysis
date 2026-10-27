#!/usr/bin/env bash

set -u
set -o pipefail

PARTITION_PATH="${1:-}"
DUCKDB="/mnt/scratch/CS131_jelenag/tools/duckdb-current/duckdb"
PROJECT_DIR=".."

if [[ -z "$PARTITION_PATH" ]]; then
    echo "Usage: $0 PARTITION_PATH" >&2
    exit 1
fi

if [[ ! -r "$PARTITION_PATH" ]]; then
    echo "Partition is not readable: $PARTITION_PATH" >&2
    exit 1
fi

FOLDER_NAME="$(basename "$(dirname "$PARTITION_PATH")")"
PARTITION_ID="${FOLDER_NAME##*=}"
OUTPUT_PATH="$PROJECT_DIR/out/partitions/${PARTITION_ID}_result.tsv"

mkdir -p "$PROJECT_DIR/out/partitions"

"$DUCKDB" "$PROJECT_DIR/work/project.duckdb" -c "
-- Takes the analysis_ready and combines all the rows with the same HCPCS_CODE and CLAIM_FROM_MONTH by summing the remaining columns --
DROP TABLE IF EXISTS hcpcs_sum;
DROP TABLE IF EXISTS duckdb_result;

CREATE TABLE hcpcs_sum AS
SELECT
    HCPCS_CODE,
    CLAIM_FROM_MONTH,
    SUM(TOTAL_CLAIM_LINES) AS TOTAL_CLAIM_LINES_SUM,
    SUM(TOTAL_PAID) AS TOTAL_PAID_SUM
FROM read_parquet('$PARTITION_PATH')
GROUP BY
    HCPCS_CODE,
    CLAIM_FROM_MONTH
ORDER BY
    HCPCS_CODE ASC,
    CLAIM_FROM_MONTH ASC;

-- Takes the hcpcs_sum just generated and, first groups them by HCPCS_CODE, then looks for the lowest/highest claim month and amount paid out --
CREATE TABLE duckdb_result AS

-- Rank sorts them first which makes ties determinsitic (ties should take the "lowest" or oldest month)
WITH ranked AS (
    SELECT
        HCPCS_CODE,
        CLAIM_FROM_MONTH,
        TOTAL_CLAIM_LINES_SUM,
        TOTAL_PAID_SUM,

        ROW_NUMBER() OVER (
            PARTITION BY HCPCS_CODE
            ORDER BY
                ROUND(TOTAL_PAID_SUM / TOTAL_CLAIM_LINES_SUM, 2) ASC,
                CLAIM_FROM_MONTH ASC
        ) AS paid_asc_rank,

        ROW_NUMBER() OVER (
            PARTITION BY HCPCS_CODE
            ORDER BY
                ROUND(TOTAL_PAID_SUM / TOTAL_CLAIM_LINES_SUM, 2) DESC,
                CLAIM_FROM_MONTH ASC
        ) AS paid_desc_rank,

        ROW_NUMBER() OVER (
            PARTITION BY HCPCS_CODE
            ORDER BY
                TOTAL_CLAIM_LINES_SUM ASC,
                CLAIM_FROM_MONTH ASC
        ) AS demand_asc_rank,

        ROW_NUMBER() OVER (
            PARTITION BY HCPCS_CODE
            ORDER BY
                TOTAL_CLAIM_LINES_SUM DESC,
                CLAIM_FROM_MONTH ASC
        ) AS demand_desc_rank

    FROM hcpcs_sum
)
SELECT
    HCPCS_CODE,

    MAX(CASE
        WHEN paid_asc_rank = 1
        THEN CLAIM_FROM_MONTH
    END) AS LOWEST_PAID_MONTH,

    MAX(CASE
        WHEN paid_desc_rank = 1
        THEN CLAIM_FROM_MONTH
    END) AS HIGHEST_PAID_MONTH,

    MAX(CASE
        WHEN demand_asc_rank = 1
        THEN CLAIM_FROM_MONTH
    END) AS LOWEST_DEMAND_MONTH,

    MAX(CASE
        WHEN demand_desc_rank = 1
        THEN CLAIM_FROM_MONTH
    END) AS HIGHEST_DEMAND_MONTH

FROM ranked
GROUP BY
    HCPCS_CODE
ORDER BY
    HCPCS_CODE ASC;

COPY duckdb_result
TO '$OUTPUT_PATH'
(HEADER, DELIMITER '\t');"

if [[ ! -s "$OUTPUT_PATH" ]]; then
    echo "Output was not created: $OUTPUT_PATH" >&2
    exit 1
fi

echo "Created: $OUTPUT_PATH"
