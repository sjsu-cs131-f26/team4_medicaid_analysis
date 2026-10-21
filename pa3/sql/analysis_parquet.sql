-- Takes the analysis_ready and combines all the rows with the same HCPCS_CODE and CLAIM_FROM_MONTH by summing the remaining columns --
CREATE TABLE hcpcs_sum AS
SELECT
    HCPCS_CODE,
    CLAIM_FROM_MONTH,
    SUM(TOTAL_CLAIM_LINES) AS TOTAL_CLAIM_LINES_SUM,
    SUM(TOTAL_PAID) AS TOTAL_PAID_SUM
FROM read_parquet('../work/analysis_ready.parquet')
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
TO '../out/duckdb_parquet_result.tsv'
(HEADER, DELIMITER '\t');

