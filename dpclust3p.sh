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
        echo "Updated: 10.13.21"
        echo
        echo "A wrapper for the dpclust3p algorithm."
        echo "It builds and launches the command to execute the OpenGenomics/dpclust3p CWL CommandLineTool within a docker container, "
        echo "then returns the output file. "
        echo
        echo "NOTE #1: All tool-related files must be in the same directory as *this* script. This does not include the Mutect VCF,"
        echo "ASCAT, or metadata files."
	echo "NOTE #2: The TMPJSON is a JSON template found in the same directory as *this* script. Do not modify this file."
        echo
        echo "Usage: $0 [ -v $VCFPATH -c $CNAPATH -s $SAMPLEID -u $PURITY -l $PLOIDY -g $GENDER -o $OUTDIR"
        echo
	echo " [-v VCFPATH]   - Full path and name of the input VCF file [string]"
	echo " [-c CNAPATH]   - Full path and name of the input ASCAT (Battenberg) copy number alteration file [string]" 
	echo " [-s SAMPLEID]  - Sample identifier in the format of TCGA-XX-XXXX [string]"
        echo " [-u PURITY]    - Tumor purity [float]"
        echo " [-l PLOIDY]    - Tumor ploidy [float]"
        echo " [-g GENDER]    - Patient gender ('male'|'female') [string]"
	echo " [-o OUTDIR]    - Full path and name to the 'dpclust' directory [string]"
        exit
}


while getopts ":v:c:s:u:l:g:o:h" Option
        do
        case $Option in
                v ) VCFPATH="$OPTARG" ;;
                c ) CNAPATH="$OPTARG" ;;
		s ) SAMPLE="$OPTARG" ;;
                u ) PURITY="$OPTARG" ;;
                l ) PLOIDY="$OPTARG" ;;
                g ) GENDER="$OPTARG" ;;
		o ) OUTDIR="$OPTARG" ;;
                h ) usage ;;
                * ) echo "unrecognized argument. use '-h' for usage information."; exit -1 ;;
        esac
done
shift $(($OPTIND - 1))

if [[ "$VCFPATH" == "" || "$CNAPATH" == "" || "$PURITY" == "" || "$PLOIDY" == "" || "$GENDER" == "" || "$OUTDIR" == "" || "$SAMPLEID" == "" ]]
        usage
fi

source /home/groups/EllrottLab/activate_conda

DRIVERS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

WORKDIR=`mktemp -d -p /mnt/scratch/ dpclust3p.XXX`
chmod -R 775 $WORKDIR
chmod -R g+s $WORKDIR

TMPJSON=./dpclust3p.template.json
CWL=./dpclust3p.cwl
JSON=$WORKDIR/dpclust3p.json

sed -e "s|vcf_in|$WORKDIR\/`basename $VCFPATH`|g" -e "s|cna_in|$WORKDIR\/`basename $CNAPATH`|g" -e "s|purity_in|$PURITY|g"-e "s|ploidy_in|$PLOIDY|g" -e "s|gender_in|$GENDER|g" -e "s|sample_in|$SAMPLE|g" $TMPJSON > $JSON

sed 's/chr//g' $VCFPATH > $WORKDIR\/`basename $VCFPATH`
sed 's/chr//g' $CNAPATH > $WORKDIR\/`basename $CNAPATH`
cp -r $CWL $WORKDIR


cd $WORKDIR
time cwltool --no-match-user $CWL $JSON

rsync -a $SAMPLE_dpInput.txt $OUTDIR

cd $DRIVERS
rm -rf $WORKDIR
