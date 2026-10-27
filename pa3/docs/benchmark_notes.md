# Task 6: Benchmark notes

## Reproduction

Run this command from the repository root on IBM:

    bash pa3/scripts/run_benchmark.sh /mnt/scratch/CS131_jelenag/projects/team04_sec02_fall2026/medicaid-provider-spending.csv

The script selects the first 1,000,000 qualifying records in source-file order using the existing team filters: TOTAL_PAID > 0 and HCPCS_CODE matching one uppercase letter followed by four digits. It keeps HCPCS_CODE, CLAIM_FROM_MONTH, TOTAL_CLAIM_LINES, and TOTAL_PAID.

Selection is deterministic for an unchanged source file, but is not random or necessarily representative. Parquet is created from those exact TSV records. Benchmark data and analysis outputs stay under pa3/work/benchmark/, separate from the committed sample outputs.

## Verification and timing

Before timing, all three implementations run and must match exactly using diff. Each timed result is also compared with that verified reference outside the timed section. All nine results passed.

Bash time measures elapsed seconds, including process startup, analysis, and result export. Input preparation and Parquet conversion are excluded. Each analysis runs in a new process.

## Results

Every run used 1,000,000 data records.

| Method | Run 1 (s) | Run 2 (s) | Run 3 (s) | Mean (s) |
|---|---:|---:|---:|---:|
| Shell over text | 2.545 | 2.483 | 2.482 | 2.503 |
| DuckDB over text | 0.636 | 0.469 | 0.501 | 0.535 |
| DuckDB over Parquet | 0.213 | 0.220 | 0.221 | 0.218 |

The benchmark text input was 28,633,271 bytes. Parquet was 8,987,133 bytes, approximately 69% smaller. These sizes describe the selected benchmark records, not the full source CSV.

DuckDB over Parquet was fastest for this input and analysis. Its mean elapsed time was approximately 59% lower than DuckDB over text. Shell and Parquet measurements were relatively consistent. DuckDB-text measurements varied more, ranging from 0.469 to 0.636 seconds.

## Interpretation and limitations

Untimed verification runs warmed the filesystem cache before timing. Runs used a fixed order: shell, DuckDB-text, then DuckDB-Parquet. Caching and changing shared-machine load may affect comparisons. Startup cost also contributes to these short measurements. These results do not establish that one tool is universally faster.

DuckDB SQL expresses grouping and ranking directly, making the analysis easier to follow and maintain than the shell implementation's intermediate files and awk logic. The measured performance and smaller Parquet input support using DuckDB with Parquet in the next project stage, with further testing on larger inputs.

Exact agreement on this benchmark does not resolve the separate discrepancy previously reported on the full dataset.

## Contribution and AI disclosure

Justin Lao implemented and ran the Task 6 benchmark workflow with AI assistance for script drafting, command explanations, and interpreting measured results. Timings were collected by executing the script on IBM. Code was hand-written with AI guidance, not AI generated.
