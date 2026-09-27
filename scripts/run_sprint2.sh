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
