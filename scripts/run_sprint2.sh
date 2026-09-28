data_folder="/mnt/scratch/CS131_jelenag/projects/team04_sec02_fall2026"

#Create sample.csv
echo "Generating Sample"
mkdir ../data/samples/
rm ../data/samples/sample_1000.csv || echo "No exisiting sample; creating one"
awk -F ',' 'BEGIN {srand(1)} NR == 1 {print $0} rand() < (1100.0 / 238015730.0) {print $0}' $data_folder/medicaid-provider-spending.csv >> ../data/samples/sample_1000.csv
echo "Succesfully Generated Sample"
echo ""

#Print sample info
echo "Header: $(head -n 1 ../data/samples/sample_1000.csv)"
echo "Rows: $(wc -l ../data/samples/sample_1000.csv)"
echo "Raw Size (bytes): $(wc -c ../data/samples/sample_1000.csv)"

# Task 3: Shell analysis artifacts

mkdir -p ../out

# 1. Frequency table by claim year
tail -n +2 "$data_folder/medicaid-provider-spending.csv" \
| cut -d',' -f4 \
| cut -d'-' -f1 \
| sort \
| uniq -c \
| sort -nr \
> ../out/freq_claim_year.txt

# 2. Frequency table by HCPCS code
tail -n +2 "$data_folder/medicaid-provider-spending.csv" \
| cut -d',' -f3 \
| sort \
| uniq -c \
| sort -nr \
> ../out/freq_hcpcs_code.txt

# 3. Top 10 servicing providers
tail -n +2 "$data_folder/medicaid-provider-spending.csv" \
| cut -d',' -f2 \
| sort \
| uniq -c \
| sort -nr \
| head -n 10 \
> ../out/top10_servicing_provider.txt

# 4. Extended-regex filter for 2023-2024 records
tail -n +2 "$data_folder/medicaid-provider-spending.csv" \
| grep -E '^[^,]*,[^,]*,[^,]*,202[34]-' \
| awk -F',' '{
    records++
    patients += $5
    claim_lines += $6
}
END {
    print "Matching records:", records
    print "Total patients:", patients
    print "Total claim lines:", claim_lines
}' \
> ../out/filter_recent_summary.txt

# 5. Deduplicated skinny table
tail -n +2 "$data_folder/medicaid-provider-spending.csv" \
| cut -d',' -f3,4 \
| sort -u \
> ../out/skinny_unique_hcpcs_claim_date.csv

# 6. Profile
{
    echo "File-size command: ls -lh $data_folder/medicaid-provider-spending.csv"
    ls -lh "$data_folder/medicaid-provider-spending.csv"

    echo "Data-row-count command: tail -n +2 $data_folder/medicaid-provider-spending.csv | wc -l"
    tail -n +2 "$data_folder/medicaid-provider-spending.csv" | wc -l
} | tee ../out/profile.txt
