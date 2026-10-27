COPY (
        SELECT *,
                SUBSTR(CLAIM_FROM_MONTH, 1, 4) AS year
         FROM read_csv_auto(
                '../work/analysis_ready.tsv', delim='\t'
        )
) TO '../work/partitions' (FORMAT parquet, PARTITION_BY (year));

