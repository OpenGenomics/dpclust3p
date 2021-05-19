#!/bin/bash
# dpclust3p.sh
#SBATCH --partition=exacloud
#SBATCH --account=spellmanlab
#SBATCH --time=10:00:00
#SBATCH --output=dp3-%j.out
#SBATCH --error=dp3-%j.err
#SBATCH --job-name=dpclust3
#SBATCH --gres disk:1024
#SBATCH --mincpus=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G

function usage()
{
        echo "dpclust3p.sh"    " [a.k.a. *this* script] "
        echo "Author: Kami E. Chiotti "
        echo "Date: 05.17.21"
        echo
        echo "A wrapper for the dpclust3p algorithm."
        echo "It builds and launches the command to execute the OpenGenomics/dpclust3p CWL CommandLineTool within a docker container, "
        echo "then returns the output file. "
        echo
        echo "NOTE #1: All input files must be in the same directory as *this* script, except for the Mutect VCF and ASCAT file."
	echo "NOTE #2: The TMPJSON is a JSON template found in the same directory as *this* script. Do not modify this file."
        echo
        echo "Usage: $0 [ -v $VCFPATH -c $CNAPATH -s $SAMPLE -o $OUTDIR"
        echo
	echo " [-v VCFPATH]   - Full path and name of the input VCF file."
	echo " [-c CNAPATH]   - Full path and name of the input ASCAT (Battenberg) copy number alteration file" 
	echo " [-s SAMPLEID]  - Sample identifier in the format of TCGA-XX-XXXX."
	echo " [-o OUTDIR]    - Full path and name to the 'dpclust' directory."
        exit
}


while getopts ":v:c:s:o:h" Option
        do
        case $Option in
                v ) VCFPATH="$OPTARG" ;;
                c ) CNAPATH="$OPTARG" ;;
		s ) SAMPLE="$OPTARG" ;;
		o ) OUTDIR="$OPTARG" ;;
                h ) usage ;;
                * ) echo "unrecognized argument. use '-h' for usage information."; exit -1 ;;
        esac
done
shift $(($OPTIND - 1))

source /home/groups/EllrottLab/activate_conda

DRIVERS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

WORKDIR=`mktemp -d -p /mnt/scratch/ dpclust3p.XXX`
chmod -R 775 $WORKDIR
chmod -R g+s $WORKDIR

TMPJSON=./dpclust3p.template.json
CWL=./dpclust3p.cwl
JSON=$WORKDIR/dpclust3p.json

sed -e "s|vcf_in|$WORKDIR\/`basename $VCFPATH`|g" -e "s|cna_in|$WORKDIR\/`basename $CNAPATH`|g" -e "s|sample_in|$SAMPLE|g" $TMPJSON > $JSON

cp -r $VCFPATH $CNAPATH $CWL $WORKDIR

cd $WORKDIR
time cwltool --no-match-user $CWL $JSON

rsync -a $SAMPLE_allDirichletProcessInfo.txt $OUTDIR

cd $DRIVERS
rm -rf $WORKDIR
