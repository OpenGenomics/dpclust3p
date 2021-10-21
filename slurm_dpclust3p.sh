#$!/user/bin/bash

METAFILE=/home/groups/Spellmandata/chiotti/gdan_pipelines/timing/dlbcl/metadata/dlbcl.meta.manifest
OUTDIR=/home/groups/Spellmandata/chiotti/gdan_pipelines/heterogeneity/tools/dpclust3p
VCFPATH=/home/groups/Spellmandata/chiotti/gdan_pipelines/timing/dlbcl/snv.indel
CNAPATH=/home/groups/Spellmandata/chiotti/gdan_pipelines/timing/dlbcl/ascat

for LINE in `cat $METAFILE`
do
SAMPLEID=`echo ${LINE:0:30}`
VCF=$VCFPATH/$SAMPLEID*.snv.indel.final.v6.annotated.vcf
CNA=$CNAPATH/`grep $SAMPLEID $METAFILE | awk '{print $2}'`
PURITY=`grep $SAMPLEID $METAFILE | awk '{print $4}'`
PLOIDY=`grep $SAMPLEID $METAFILE | awk '{print $3}'`
GENDER=`grep $SAMPLEID $METAFILE | awk '{print $5}'`

sbatch --get-user-env dpclust3p.sh -v $VCFPATH -c $CNAPATH -u $PURITY -l $PLOIDY -g $GENDER -s $SAMPLEID -o $OUTDIR
done
