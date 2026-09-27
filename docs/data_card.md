Source: https://opendata.hhs.gov/datasets/medicaid-provider-spending
Licence: Open Licence (no restriction)
Raw Size (bytes): 52521
Row Count: 1080
Format: .csv
Delimeter: ,
Header Status: BILLING_PROVIDER_NPI_NUM,SERVICING_PROVIDER_NPI_NUM,HCPCS_CODE,CLAIM_FROM_MONTH,TOTAL_PATIENTS,TOTAL_CLAIM_LINES,TOTAL_PAID

Obtained using: awk -F ',' 'BEGIN {srand(1)} NR == 1 {print $0} rand() < (1100.0 / 238015730.0) {print $0}' medicaid-provider-spending.csv >> sample.csv
Row count: wc -l ../data/samples/sample_1000.csv
Raw size: wc -c ../data/samples/sample_1000.csv
