#!/bin/bash -l


#$ -q all.q 
#$ -q short.q
#$ -pe smp 16-128
#$ -N lepto_phytree
#$ -e $HOME/Lepto/2022_Book_Chapter_Update/from_NCBI/16S_from_nuccore_refseq/job.err
#$ -o $HOME/Lepto/2022_Book_Chapter_Update/from_NCBI/16S_from_nuccore_refseq/job.out

# Set several SGE/UGE environment variables
source /opt/sge/default/common/settings.sh

cd $HOME/Lepto/2022_Book_Chapter_Update/from_NCBI/16S_from_nuccore_refseq

# Create the phylotree
module load raxml/8.2.12-PTHREAD

# 1k trees
raxmlHPC-PTHREADS-SSE3 \
  -s merged.fasta.aln.phy \
  -n topology \
  -# 1000 \
  -p 65432 \
  -f d \
  -j \
  -m GTRGAMMA \
  --JC69 \
  --no-bfgs \
  -T "${NSLOTS}"
rm *.RUN.*

# 5k bootstraps
raxmlHPC-PTHREADS-SSE3 \
	-s merged.fasta.aln.phy \
	-n boots \
	-N 5000 \
	-p 65432 \
	-x 54321 \
	-f a \
	-m GTRGAMMA \
	--JC69 \
	--no-bfgs \
	-T "${NSLOTS}"

# Overlay bootstraps onto the best tree topology file
raxmlHPC-PTHREADS-SSE3 \
  -n final \
  -t RAxML_bestTree.topology \
  -z RAxML_bootstrap.boots \
  -f b \
  -m GTRGAMMA \
  --JC69

# Confirm enough bootstraps performed
raxmlHPC-PTHREADS-SSE3 \
	-m GTRCAT \
	--JC69 \
	-p 65432 \
	-I autoMRE \
	-z RAxML_bootstrap.boots \
	-n test \
	> Test_Summary.txt


# Make pairwise similarity matrix with BLASTn and Biopython
export PATH=$LAB_HOME/.anaconda2/bin:$PATH
source activate bpy2
module load ncbi-blast+/2.9.0
python ~/genomics_scripts/split.multifasta.py \
	-i merged.fasta.aln \
	-e .fa \
	-s '' \
	-g
python ~/genomics_scripts/calc.pairwise.similarities.py \
  -e fa \
  -i `pwd` \
  --aligner blastn
python ~/my_github_scripts/pairwiseTo2d.py \
  -i Pairwise.Similarities.tab \
  -o Pairwise.Similarities.matrix.tab \
  --sort
source deactivate
rm Pairwise.Similarities.tab
