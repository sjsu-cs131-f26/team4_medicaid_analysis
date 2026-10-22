Source: https://opendata.hhs.gov/datasets/medicaid-provider-spending
Licence: Open Licence (no restriction)
Raw Size (bytes): 52521
Row Count: 1080
Format: .csv
Delimeter: ,
Header Status: BILLING_PROVIDER_NPI_NUM,SERVICING_PROVIDER_NPI_NUM,HCPCS_CODE,CLAIM_FROM_MONTH,TOTAL_PATIENTS,TOTAL_CLAIM_LINES,TOTAL_PAID

Obtained using: awk -F ',' -v total="$data_row_count" 'BEGIN {srand(1)} NR == 1 {print $0} ($1 != "" && $2 != "" && rand() < (1100.0 / total)) {print $0}' $data_folder/$data_file > $sample_folder/$sample_file
Row count: tail -n +2 $sample_folder/$sample_file | wc -l
Raw size: tail -n +2 $sample_folder/$sample_fole | wc -c
