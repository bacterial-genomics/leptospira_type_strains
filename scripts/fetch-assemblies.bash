#!/usr/bin/env bash

# Column content are:
#     "${ln[0]}"  =  Taxon
#     "${ln[1]}"  =  16S rRNA Gene Sequence Accession
#     "${ln[2]}"  =  ppk1 Gene Sequence Accession
#     "${ln[3]}"  =  RefSeq Genome Accession
#     "${ln[4]}"  =  Nomenclatural status
#     "${ln[5]}"  =  Taxonomic status
#     "${ln[6]}"  =  Misc Notes
#     "${ln[7]}"  =  Clade

module load conda
source activate bpy2

module load Entrez

i=0
while IFS=$'\t' read -r -a ln; do
	if [ "${ln[4]}" == 'validly published' ] && [ "${ln[5]}" == 'correct name' ]; then
		species="$(echo "${ln[0]}" | awk '{print $1 "_" $2}')"
		accn_refseq="$(echo "${ln[3]}")"
		python ~/genomics_scripts/genbankacc2gbk.py \
		  "${accn_refseq}" \
		  --outfile "${species}_${accn_refseq}".gbk \
		  --min-length 3000000
		((i++))
		sleep 5s
	fi
done <  List\ of\ approved\ Leptospiraceae\ species.tsv
