
CREATE TABLE hcpcs_sum AS
SELECT
    HCPCS_CODE,
    CLAIM_FROM_MONTH,
    SUM(TOTAL_CLAIM_LINES) AS TOTAL_CLAIM_LINES_SUM,
    SUM(TOTAL_PAID) AS TOTAL_PAID_SUM
FROM read_csv_auto('../work/analysis_ready.tsv', delim = '\t')
GROUP BY
    HCPCS_CODE,
    CLAIM_FROM_MONTH
ORDER BY
    HCPCS_CODE ASC,
    CLAIM_FROM_MONTH ASC;

CREATE TABLE duckdb_result AS
WITH ranked AS (
    SELECT
        HCPCS_CODE,
        CLAIM_FROM_MONTH,
        TOTAL_CLAIM_LINES_SUM,
        TOTAL_PAID_SUM,

        ROW_NUMBER() OVER (
            PARTITION BY HCPCS_CODE
            ORDER BY
                ROUND(
                    TOTAL_PAID_SUM / NULLIF(TOTAL_CLAIM_LINES_SUM, 0),
                    2
                ) ASC NULLS LAST,
                CLAIM_FROM_MONTH ASC
        ) AS paid_asc_rank,

        ROW_NUMBER() OVER (
            PARTITION BY HCPCS_CODE
            ORDER BY
                ROUND(
                    TOTAL_PAID_SUM / NULLIF(TOTAL_CLAIM_LINES_SUM, 0),
                    2
                ) DESC NULLS LAST,
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
TO '../out/duckdb_text_result.tsv'
(HEADER, DELIMITER '\t');

