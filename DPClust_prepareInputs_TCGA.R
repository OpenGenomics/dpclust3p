## ################################################################
## Pipeline to preprocess TCGA mutect2 and ascat files for dpclust
## ################################################################
args <- commandArgs(TRUE)
VCFPATH <- toString(args[1]) ## path to vcf file (mutect2 calls with format "AD" ref,alt counts)
CNAPATH <- toString(args[2]) ## path to copy-number segments file (ascat)
SAMPLEID <- toString(args[3]) ## sample id
PURITY <- as.numeric(args[4]) ## tumor purity
PLOIDY <- as.numeric(args[5]) ## tumor ploidy
GENDER <- toString(args[6])
WORKINGDIR <- toString(args[7]) ## working directory (all outputs go here)
## ################################################################
## author: maxime.tarabichi@ulb.be, maxime.tarabichi@crick.ac.uk
## updated: chiotti@ohsu.edu 10.13.21
## ################################################################


## ################################################################
## test
#if(F){
#VCFPATH <- "../INPUT/28d05b94-b56b-4abd-bbeb-9108b20c35ab.vcf"
#CNAPATH <- "../INPUT/TCGA-CHOL.3787a76c-f1bc-4c98-8497-6d9040cc1760.ascat2.allelic_specific.seg.txt"
#SAMPLEID <- "TCGA-4G-AAZO"
#WORKINGDIR <- getwd()
#}
## ################################################################


## ################################################################
setwd(WORKINGDIR)
## ################################################################

## ################################################################
## path to summary of TCGA purity/ploidy/gender
##PATHSUMMARY <- "/opt/dpclust3p/summary.ascatTCGA.penalty70.txt"
## ################################################################

## ################################################################
## package dependencies for this script
## for dpclust3p, other dependencies (see: https://github.com/Wedge-lab/dpclust3p):
## source("http://bioconductor.org/biocLite.R"); biocLite(c("optparse","VariantAnnotation","GenomicRanges","Rsamtools","ggplot2","IRanges","S4Vectors","reshape2"))'
## devtools::install_github("Wedge-Oxford/dpclust3p")
library(data.table)
library(dpclust3p)
## ################################################################


## ################################################################
## functions to read in data
## ################################################################
readVCF <- function(VCFPATH) ## keeps "PASS", keeps SNV
{
    vcf <- as.data.frame(data.table::fread(VCFPATH, skip="#CHROM"))
    vcf[,1]=gsub(vcf[,1], pattern="chr", replacement="")
    colnames(vcf)[(ncol(vcf)-1):ncol(vcf)]=c("NORMAL","TUMOR")
    vcf[vcf$FILTER=="PASS" & nchar(vcf$ALT)==1 & nchar(vcf$REF)==1,]
}

readCNA <- function(CNAPATH)
{
    cna=as.data.frame(data.table::fread(CNAPATH))
    cna$Chromosome=gsub(cna$Chromosome, pattern="chr", replacement="")
    cna
}
## ################################################################


## ################################################################
## functions to prepare all DPClust inputs
## ################################################################
writeRhoPsi <- function(rhopsifile, aberrant_cell_fraction, ploidy)
{
    cp <- cbind(1-aberrant_cell_fraction,ploidy)
    cp <- cbind(cp,2*(1-cp[1,1])+cp[1,2]*cp[1,1])
    colnames(cp) <- c("cellularity","ploidy","psi")
    RP <- matrix(NA,3,5)
    colnames(RP) <- c("rho", "psi", "ploidy", "distance", "is.best")
    rownames(RP) <- c("ASCAT","FRAC_GENOME","REF_SEG")
    RP[3,4] <- "Inf"
    RP[3,5] <- "FALSE"
    RP[2,5] <- "TRUE"
    RP[2,4] <- .42
    RP[1,1:3] <- cp[c(1,3,2)]
    RP[2,1:3] <- cp[c(1,3,2)]
    write.table(RP,file=rhopsifile,sep="\t",col.names=T,row.names=T,quote=F)
}

createLociFile <- function(vcfdat, outfile, chrom_col, pos_col, ref_col, alt_col)
{
    loci = vcfdat[, c(chrom_col, pos_col, ref_col, alt_col)]
    write.table(loci, file=outfile, sep="\t", quote=F, row.names=F, col.names=F)
}


writeCellularity <- function(cellularity_file,aberrant_cell_fraction, ploidy)
{
    cp <- cbind(1-aberrant_cell_fraction,ploidy)
    cp <- cbind(cp,2*(1-cp[1,1])+cp[1,2]*cp[1,1])
    colnames(cp) <- c("cellularity","ploidy","psi")
    write.table(cp,file=cellularity_file,sep="\t",col.names=T,row.names=T,quote=F)
}

writeBBlike.ASCAT <- function(ascat,ASCATFILE)
{
    cn <- c("chr", "startpos", "endpos", "BAF", "pval",
            "LogR", "ntot", "nMaj1_A", "nMin1_A", "frac1_A",
            "nMaj2_A", "nMin2_A", "frac2_A", "SDfrac_A",
            "SDfrac_A_BS", "frac1_A_0.025", "frac1_A_0.975", "nMaj1_B",
            "nMin1_B", "frac1_B", "nMaj2_B", "nMin2_B", "frac2_B", "SDfrac_B",
            "SDfrac_B_BS", "frac1_B_0.025", "frac1_B_0.975", "nMaj1_C", "nMin1_C",
            "frac1_C", "nMaj2_C", "nMin2_C", "frac2_C", "SDfrac_C",
            "SDfrac_C_BS", "frac1_C_0.025", "frac1_C_0.975", "nMaj1_D",
            "nMin1_D", "frac1_D", "nMaj2_D", "nMin2_D", "frac2_D", "SDfrac_D",
            "SDfrac_D_BS", "frac1_D_0.025", "frac1_D_0.975", "nMaj1_E",
            "nMin1_E", "frac1_E", "nMaj2_E", "nMin2_E", "frac2_E", "SDfrac_E",
            "SDfrac_E_BS", "frac1_E_0.025", "frac1_E_0.975", "nMaj1_F", "nMin1_F",
            "frac1_F", "nMaj2_F", "nMin2_F", "frac2_F", "SDfrac_F", "SDfrac_F_BS",
            "frac1_F_0.025","frac1_F_0.975")
    bb <- matrix("NA",nrow(ascat),length(cn))
    colnames(bb) <- cn
    bb[,1] <- as.character(ascat[,"Chromosome"])
    bb[,2] <- as.character(ascat[,"Start"])
    bb[,3] <- as.character(ascat[,"End"])
    bb[,5] <- rep("1",nrow(ascat))
    bb[,8] <- as.character(ascat[,"Major_Copy_Number"])
    bb[,9] <- as.character(ascat[,"Minor_Copy_Number"])
    bb[,10] <- rep("1",nrow(ascat))
    bb <- as.data.frame(bb)
    bb[,1] <- as.factor(as.character(bb[,1]))
    bb[,2] <- as.numeric(as.character(bb[,2]))
    bb[,3] <- as.numeric(as.character(bb[,3]))
    bb[,5] <- as.numeric(as.character(bb[,5]))
    bb[,8] <- as.numeric(as.character(bb[,8]))
    bb[,9] <- as.numeric(as.character(bb[,9]))
    bb[,10] <- as.numeric(as.character(bb[,10]))
    write.table(bb,file=ASCATFILE,sep="\t",col.names=T,row.names=F,quote=F)
    NULL
}

mutwt2allelecounts <- function(counts.alt, counts.ref, allele.alt, allele.ref)
{
    output = array(0, c(length(allele.ref), 4))
    nucleotides = c("A", "C", "G", "T")
    nucleo.index = match(allele.alt, nucleotides)
    for (i in 1:nrow(output)) {
        output[i,nucleo.index[i]] = counts.alt[i]
    }
    nucleo.index = match(allele.ref, nucleotides)
    for (i in 1:nrow(output)) {
        output[i,nucleo.index[i]] = counts.ref[i]
    }
    return(output)
}

getCounts <- function(vec_annot, vec_info)
{
    wAD <- sapply(strsplit(vec_annot,split=":"),function(x) which(x=="AD"))
    INFO <- strsplit(vec_info,split=":")
    AD <- sapply(1:length(INFO),function(x) INFO[[x]][wAD[x]])
    stopifnot(length(INFO)==length(AD))
    refalt <- strsplit(AD,split=",")
    list(ref=as.numeric(sapply(refalt,"[",1)),
         alt=as.numeric(sapply(refalt,"[",2)))
}

createAlleleCountsFile <- function(vcfdat, outfile)
{
    if (length(vcfdat$TUMOR)>0){tmr="TUMOR"}else{tmr="tumor"}
    CT <- getCounts(vcfdat[,"FORMAT"],vcfdat[,tmr])
    counts_table <- mutwt2allelecounts(counts.alt=CT$alt,
                                       counts.ref=CT$ref,
                                       allele.alt=as.character(vcfdat[,"ALT"]),
                                       allele.ref=as.character(vcfdat[,"REF"]))
    output <- data.frame(as.character(vcfdat[,1]), vcfdat[,2],
                         counts_table, rowSums(counts_table))
    colnames(output) <- c("#CHR","POS","Count_A",
                          "Count_C",
                          "Count_G","Count_T","Good_depth")
    write.table(output, file=outfile, sep="\t", quote=F, row.names=F)
}

prepareDPinput <- function(segments, aberrant_cell_fraction, ploidy)
{
    tnull <- writeBBlike.ASCAT(segments,BBFILE)
    writeCellularity(cellularity_file,aberrant_cell_fraction, ploidy)
    writeRhoPsi(battenberg_rho_psi_file,aberrant_cell_fraction, ploidy)
}

writeDPfile <- function(dpFile="dpInput.txt",
                        battenberg_rho_psi_file,
                        VCFPATH,
                        BBFILE,
                        GENDER)
{
  vcfdat <- readVCF(VCFPATH)
  createLociFile(vcfdat, loci_file, 1,2,4,5)
  createAlleleCountsFile(vcfdat, allelecounts_file)
  suppressWarnings(runGetDirichletProcessInfo(loci_file=loci_file,
                                              allele_frequencies_file=allelecounts_file,
                                              cellularity_file=battenberg_rho_psi_file,
                                              subclone_file=BBFILE,
                                              gender=GENDER,
                                              SNP.phase.file="NA",
                                              mut.phase.file="NA",
                                              output_file=dpFile))
}
## ################################################################


## ################################################################
outdir <- file.path(WORKINGDIR,SAMPLEID)
if (!file.exists(outdir)) { dir.create(outdir) }

BBFILE <- file.path(outdir,paste0(SAMPLEID,"_bb_like_ascat.tsv"))
battenberg_rho_psi_file <- file.path(outdir,paste0(SAMPLEID,"_ASCAT_rho_and_psi.txt"))
cellularity_file <- file.path(outdir,paste0(SAMPLEID,"_ASCAT_cellularity_ploidy.txt"))
loci_file  <-  file.path(outdir,paste0(SAMPLEID,"_loci.txt"))
allelecounts_file  <-  file.path(paste0(SAMPLEID,"_alleleCounts.txt"))
DPFILE <- file.path(paste0(SAMPLEID,"_dpInput.txt"))
## ################################################################


## ################################################################
#pp_summary <- read.table(PATHSUMMARY,sep="\t",header=T)
#purity <- pp_summary[pp_summary$name==SAMPLEID,"purity"]
purity <- PURITY
#ploidy <- pp_summary[pp_summary$name==SAMPLEID,"ploidy"]
ploidy <- PLOIDY
#gender <- ifelse(pp_summary[pp_summary$name==SAMPLEID,"sex"]=="XY","male","female")
gender <- GENDER
cna <- readCNA(CNAPATH)
## ################################################################



## ################################################################
## From ASCAT-like to Battenberg-like inputs
prepareDPinput(segments=cna,
               aberrant_cell_fraction=purity,
               ploidy=ploidy)
## ################################################################


## ################################################################
## TCGA format pre-processing and DPClust input generation
## ################################################################
writeDPfile(dpFile=DPFILE,
            battenberg_rho_psi_file,
            VCFPATH=VCFPATH,
            BBFILE=BBFILE,
            GENDER=gender)
## ################################################################


## ################################################################
q(save="no")
## ################################################################
