#!/usr/bin/env bash


### Fetch RefSeq assemblies
ml miniconda
conda activate ncbi-datasets

while IFS=$'\t' read -r taxon acc; do
    [ -z "$acc" ] && continue

    species=$(echo "$taxon" | awk '{print $1"_"$2}')
    outbase="${species}_${acc}"
    outdir="tmp_${outbase}"
    gff_out="${outbase}.gff"
    gbk_out="${outbase}.gbk"
 
    echo "Downloading ${taxon} (${acc}) -> ${gff_out}, ${gbk_out} ..."
    rm -rf "$outdir" "${outbase}.zip"

    # 1) Download genome package for this RefSeq accession
    #    Include both GFF3 and GenBank formats
    datasets download genome accession "$acc" \
        --include gff3,gbff \
        --filename "${outbase}.zip"

    # 2) Unpack
    mkdir -p "$outdir"
    unzip -q "${outbase}.zip" -d "$outdir"

    # 3a) Find the GFF3 inside the NCBI datasets structure
    gff_file=$(
        find "$outdir" -type f \( -name "*.gff" -o -name "*.gff3" \) | head -n 1 || true
    )
    if [ -z "$gff_file" ]; then
        echo "ERROR: No GFF found for ${acc} (${taxon})" >&2
        exit 1
    else
        mv "$gff_file" "$gff_out"
        echo "Saved $gff_out"
    fi

    # 3b) Find the GenBank file (usually .gbff)
    gbk_file=$(
        find "$outdir" -type f \( -name "*.gbk" -o -name "*.gbff" \) | head -n 1 || true
    )
    if [ -z "$gbk_file" ]; then
        echo "ERROR: No GenBank (GBK/GBFF) found for ${acc} (${taxon})" >&2
        exit 1
    else
        mv "$gbk_file" "$gbk_out"
        echo "Saved $gbk_out"
    fi

    # 4) Clean up tmp
    rm -rf "$outdir" "${outbase}.zip"
done < <(grep '^Leptospira' RefSeq-genome-accessions.tsv)




### Extract the ppk1 locus tag from each assembly file
echo -e "Taxon\tppk Locus Tag" > ppk-locus_tag-from-RefSeq.tsv
for file in *.gff; do
    taxon=$(echo $file | cut -d _ -f 1,2)
    locus_tag=$(grep "Name=ppk1" "${file}" | sed 's/.*;locus_tag=\([^;]*\).*/\1/')
    echo -e "${taxon}\t${locus_tag}" >> ppk-locus_tag-from-RefSeq.tsv
done

pigz *.{gbk,gff}

### Extract the secY locus tag from each assembly file
echo -e "Taxon\tsecY Locus Tag" > secY-locus_tag-from-RefSeq.tsv
for file in *.gff.gz; do
    taxon=$(echo $file | cut -d _ -f 1,2)
    locus_tag=$(zgrep "Name=secY" "${file}" | sed 's/.*;locus_tag=\([^;]*\).*/\1/')
    echo -e "${taxon}\t${locus_tag}" >> secY-locus_tag-from-RefSeq.tsv
done

