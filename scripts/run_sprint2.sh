#Global variables
echo "Reading data-set metadata..."
data_folder="/mnt/scratch/CS131_jelenag/projects/team04_sec02_fall2026"
data_file="medicaid-provider-spending.csv"
data_file_size=$(wc -l $data_folder/$data_file | cut -d' ' -f1)
sample_folder="../data/samples"
sample_file="sample_1000.csv"
out_folder="../out"




#Task 2: Create sample.csv
echo "Generating Sample..."
mkdir -p $sample_folder
awk -F ',' -v total="$data_file_size" 'BEGIN {srand(1)} NR == 1 {print $0} rand() < (1100.0 / total) {print $0}' $data_folder/$data_file > $sample_folder/$sample_file
echo "Succesfully Generated Sample:"

#Print sample info
echo -e "\tHeader: $(head -n 1 $sample_folder/$sample_file)"
echo -e "\tRows: $(tail -n +2 $sample_folder/$sample_file | wc -l $sample_folder/$sample_file)"
echo -e "\tRaw Size (bytes): $(wc -c $sample_folder/$sample_file)"
echo ""



# Task 3: Shell analysis artifacts

mkdir -p $out_folder

# 1. Frequency table by claim year
echo "Creaing frequency table by claim year..."
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f4 \
| cut -d'-' -f1 \
| sort \
| uniq -c \
| sort -nr \
> $out_folder/freq_claim_year.txt

# 2. Frequency table by HCPCS code
echo "Creating frequency table by HCPCS code..."
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f3 \
| sort \
| uniq -c \
| sort -nr \
> $out_folder/freq_hcpcs_code.txt

# 3. Top 10 servicing providers
echo "Creating top 10 servicing providers..."
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f2 \
| sort \
| uniq -c \
| sort -nr \
| head -n 10 \
> $out_folder/top10_servicing_provider.txt

# 4. Extended-regex filter for 2023-2024 records
echo "Creating filter for 2023-2024 records..."
tail -n +2 "$sample_folder/$sample_file" \
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
> $out_folder/filter_recent_summary.txt

# 5. Deduplicated skinny table
echo "Creating deduplicated skinny table..."
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f3,4 \
| sort -u \
> $out_folder/skinny_unique_hcpcs_claim_date.csv

# 6. Profile
echo "Creating profile:"
echo "-------------------------------"
{
    echo "File-size command: ls -lh $sample_folder/$sample_file"
    ls -lh "$sample_folder/$sample_file"

    echo "Data-row-count command: tail -n +2 $sample_folder/$sample_file | wc -l"
    tail -n +2 "$sample_folder/$sample_file" | wc -l
} | tee $out_folder/profile.txt
echo "-------------------------------"

echo ""
echo "DONE"
