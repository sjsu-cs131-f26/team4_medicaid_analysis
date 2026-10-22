#Global variables
echo ""
echo "Reading data-set metadata..."
start_time=$(date +%s.%N)

data_folder="/mnt/scratch/CS131_jelenag/projects/team04_sec02_fall2026"
data_file="medicaid-provider-spending.csv"
data_row_count=$(wc -l $data_folder/$data_file | cut -d' ' -f1)
sample_folder="../data/samples"
sample_file="sample_1000.csv"
out_folder="../out"

echo -e "\tMedicaid data set: $data_folder/$data_file"
echo -e "\tMedicaid row count: $data_row_count"
echo -e "\tSample file: $sample_folder/$sample_file"
echo -e "\tOutput dir: $out_folder"

end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Reading data-set metadata: $elapsed seconds" > $out_folder/time.txt




#Task 2: Create sample.csv
echo "Generating Sample..."
start_time=$(date +%s.%N)

mkdir -p $sample_folder
awk -F ',' -v total="$data_row_count" 'BEGIN {srand(1)} NR == 1 {print $0} ($1 != "" && $2 != "" && rand() < (1100.0 / total)) {print $0}' $data_folder/$data_file > $sample_folder/$sample_file

#Print sample info
echo -e "\tHeader: $(head -n 1 $sample_folder/$sample_file)"
echo -e "\tRows: $(tail -n +2 $sample_folder/$sample_file | wc -l)"
echo -e "\tRaw Size (bytes): $(wc -c $sample_folder/$sample_file)"
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Generating Sample: $elapsed seconds" >> $out_folder/time.txt



# Task 3: Shell analysis artifacts

mkdir -p $out_folder

# 1. Frequency table by claim year
echo "Creaing frequency table by claim year..."
start_time=$(date +%s.%N)
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f4 \
| cut -d'-' -f1 \
| sort \
| uniq -c \
| sort -nr \
> $out_folder/freq_claim_year.txt
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Frequency table by claim year: $elapsed seconds" >> $out_folder/time.txt



# 2. Frequency table by HCPCS code
echo "Creating frequency table by HCPCS code..."
start_time=$(date +%s.%N)
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f3 \
| sort \
| uniq -c \
| sort -nr \
> $out_folder/freq_hcpcs_code.txt
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Frequency table by HCPCS code: $elapsed seconds" >> $out_folder/time.txt



# 3. Top 10 servicing providers
echo "Creating top 10 servicing providers..."
start_time=$(date +%s.%N)
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f2 \
| sort \
| uniq -c \
| sort -nr \
| head -n 10 \
> $out_folder/top10_servicing_provider.txt
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Top 10 servicing providers: $elapsed seconds" >> $out_folder/time.txt



# 4. Extended-regex filter for 2023-2024 records
echo "Creating filter for 2023-2024 records..."
start_time=$(date +%s.%N)
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
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Regex from 2023-2024: $elapsed seconds" >> $out_folder/time.txt



# 5. Deduplicated skinny table
echo "Creating deduplicated skinny table..."
start_time=$(date +%s.%N)
tail -n +2 "$sample_folder/$sample_file" \
| cut -d',' -f3,4 \
| sort -u \
> $out_folder/skinny_unique_hcpcs_claim_date.csv
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Skinny table: $elapsed seconds" >> $out_folder/time.txt



# 6. Profile
echo "Creating profile..."
start_time=$(date +%s.%N)
echo "-------------------------------"
{
    echo "File-size command: wc -c \"$sample_folder/$sample_file\" | cut -d' ' -f1"
    echo "$(wc -c "$sample_folder/$sample_file" | cut -d' ' -f1) bytes"

    echo "Data-row-count command: tail -n +2 \"$sample_folder/$sample_file\" | wc -l"
    echo "$(tail -n +2 "$sample_folder/$sample_file" | wc -l) lines"
} | tee $out_folder/profile.txt
echo "-------------------------------"
end_time=$(date +%s.%N)
elapsed=$(echo "$end_time - $start_time" | bc)
echo -e "...Completed (time elapsed: $elapsed seconds)\n"
echo -e "Profile: $elapsed seconds" >> $out_folder/time.txt

