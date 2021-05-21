#$!/user/bin/bash

VCFPATH=/home/groups/Spellmandata/chiotti/gdan_pipelines/heterogeneity/seq/dpclust3p_in.mutect.vcf
CNAPATH=/home/groups/Spellmandata/chiotti/gdan_pipelines/heterogeneity/seq/dpclust3p_in.battenberg.txt
SAMPLEID=TCGA-4G-AAZO
OUTDIR=/home/groups/Spellmandata/chiotti/gdan_pipelines/heterogeneity/tools/dpclust3p/
sbatch --get-user-env dpclust3p.sh -v $VCFPATH -c $CNAPATH -s $SAMPLEID -o $OUTDIR

