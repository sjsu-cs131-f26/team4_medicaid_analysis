COPY (
	SELECT * FROM read_csv_auto(
		'../work/analysis_ready.tsv', delim='\t'
	)
) TO '../work/analysis_ready.parquet' (FORMAT parquet);
