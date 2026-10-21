# Main input and output
dataset_file=$"../work/analysis_ready.tsv"
output_file=$"../out/shell_result.tsv"

# Sum patients and amount paid for each unique combination of HCPCS_CODE and CLAIM_MONTH
awk -F"\t" '
	( NR != 1 ) { total_patients[$1][$2] += $3; total_paid[$1][$2] += $4 } 
	END { 
		for (hcpcs in total_patients) { 
			for (month in total_patients[hcpcs]) { 
				print hcpcs "\t" month "\t" total_patients[hcpcs][month] "\t" total_paid[hcpcs][month] 
			} 
		} 
	}
' $dataset_file | sort | awk -F"\t" 'BEGIN {print "HCPCS_CODE\tCLAIM_MONTH\tTOTAL_PATIENTS\tTOTAL_PAID"} { print$0 }' > "../work/shell_hcpcs_sum.tsv"

# Iterate shell_hcpcs_sum and find the highest/lowest TOTAL_PAID and TOTAL_PATIENTS
awk -F"\t" '
	( NR != 1 ) { 
		curr_hcpcs=$1
		curr_claim_month=$2
		curr_total_patients=$3
		curr_total_paid=$4
		curr_avg_paid=(curr_total_paid/curr_total_patients)

		if ((lowest_paid_month[curr_hcpcs] == 0)) {
			lowest_paid[curr_hcpcs]=curr_avg_paid
			lowest_paid_month[curr_hcpcs]=curr_claim_month
		}

		if ((lowest_patients_month[curr_hcpcs] == 0)) {
			lowest_patients[curr_hcpcs]=curr_total_patients
			lowest_patients_month[curr_hcpcs]=curr_claim_month
		}

		if ((lowest_paid[curr_hcpcs] >= curr_avg_paid)) {
			if ((lowest_paid[curr_hcpcs] == curr_avg_paid)) {
                        	if ((curr_claim_month "") < (lowest_paid_month[curr_hcpcs] "")) { lowest_paid_month[curr_hcpcs]=curr_claim_month }
			} else {
				lowest_paid[curr_hcpcs]=curr_avg_paid
				lowest_paid_month[curr_hcpcs]=curr_claim_month
			}
		}
		if ((lowest_patients[curr_hcpcs] >= curr_total_patients)) {
                        if ((lowest_patients[curr_hcpcs] == curr_total_patients)) {
                                if ((curr_claim_month "") < (lowest_patients_month[curr_hcpcs] "")) { lowest_patients_month[curr_hcpcs]=curr_claim_month }
                        } else {
                                lowest_patients[curr_hcpcs]=curr_total_patients
                                lowest_patients_month[curr_hcpcs]=curr_claim_month
                        }
		}

                if ((highest_paid[curr_hcpcs] <= curr_avg_paid)) {

                        if ((highest_paid[curr_hcpcs] == curr_avg_paid)) {
                                if ((curr_claim_month "") < (highest_paid_month[curr_hcpcs] "")) { highest_paid_month[curr_hcpcs]=curr_claim_month }
                        } else {
                                highest_paid[curr_hcpcs]=curr_avg_paid
                                highest_paid_month[curr_hcpcs]=curr_claim_month
                        }
                }
                if ((highest_patients[curr_hcpcs] <= curr_total_patients)) {

                        if ((highest_patients[curr_hcpcs] == curr_total_patients)) {
                                if ((curr_claim_month "") < (highest_patients_month[curr_hcpcs] "")) { highest_patients_month[curr_hcpcs]=curr_claim_month }
                        } else {
                                highest_patients[curr_hcpcs]=curr_total_patients
                                highest_patients_month[curr_hcpcs]=curr_claim_month
                        }
                }
	}
	END {
		for ( hcpcs in lowest_paid ) {
			print hcpcs "\t" lowest_paid_month[hcpcs] "\t" highest_paid_month[hcpcs] "\t" lowest_patients_month[hcpcs] "\t" highest_patients_month[hcpcs]
		}
	}

' "../work/shell_hcpcs_sum.tsv" | sort | awk -F"\t" 'BEGIN { print "HCPCS_CODE\tLOWEST_PAID_MONTH\tHIGHEST_PAID_MONTH\tLOWEST_DEMAND_MONTH\tHIGHEST_DEMAND_MONTH" } { print $0 }' > $output_file
echo "SHELL DONE"
