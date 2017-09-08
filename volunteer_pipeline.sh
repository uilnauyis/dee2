#!/bin/bash
#sra2mx
#Copyright Mark Ziemann 2015 to 2017 mark.ziemann@gmail.com

set -x

MY_ORG=$1
MEM_FACTOR=2

main(){
#logging all commands
set -x

#allow aliasing and define exit
shopt -s expand_aliases
alias exit="rm *fastq *.sra *tsv ; return 1"

#JOB
SRR_FILE=$1
SRR=$(basename $SRR_FILE .sra)
echo $SRR
##ORGANISM
ORG=$2

#exec 2>> $SRR.log ; exec >&1

#ENVIRONMENT VARS
CODE_DIR=$(pwd)
DEE_DIR=$(dirname $CODE_DIR)
PIPELINE=$CODE_DIR/$0
PIPELINE_MD5=$(md5sum $PIPELINE | cut -d ' ' -f1)
SW_DIR=$DEE_DIR/sw
PATH=$PATH:$SW_DIR
DATA_DIR=$DEE_DIR/data/$ORG
REF_DIR=$DEE_DIR/ref
QC_DIR=$DEE_DIR/qc

#echo running $PIPELINE $SRR_FILE $ORG
#exit

#SOFTWARE VARS
#VDBVAL=$SW_DIR/vdb-validate
#FQDUMP=$SW_DIR/fastq-dump
#ABIDUMP=$SW_DIR/abi-dump
#SRA_STAT=$SW_DIR/sra-stat
#PFQDUMP=$SW_DIR/parallel-fastq-dump
#FASTQC=$SW_DIR/FastQC/fastqc
#SKEWER=$SW_DIR/skewer
#MINION=$SW_DIR/kraken/./minion
#BOWTIE2=$SW_DIR/bowtie2-2.3.1/bowtie2
#BOWTIE2BUILD=$SW_DIR/bowtie2-2.3.1/bowtie2-build
#SOLIDTRIMMER=$SW_DIR/solid-trimmer.py
#STAR=$SW_DIR/STAR
#SUBJUNC=/data/app/bin/subjunc
#FEATURECOUNTS=$SW_DIR/featureCounts
#KALLISTO=$SW_DIR/kallisto

#LIMITS
DISKLIM=32000000
DLLIM=1
ALNLIM=2
MEMALNLIM=4
THREADS=$(nproc)
DISK=$(df . | awk 'END{print$4}')
MEM=$(free | awk '$1 ~ /Mem:/  {print $2-$3}')

##########################################################################
# Lets test all the input variables
##########################################################################
#check if these are directories
if [ ! -d "$DATA_DIR"  ] ; then
  mkdir -p $DATA_DIR
fi

if [ ! -d "$QC_DIR" ] ; then
  mkdir -p $QC_DIR
fi

#check that all the software is present and working
#FQDUMP_STATUS=$($FQDUMP -h | grep -xc './fastq-dump : 2.8.2')
#ABIDUMP_STATUS=$($ABIDUMP -h | grep -xc './abi-dump : 2.8.2')
#SKEWER_STATUS=$SW_DIR/skewer
#SOLIDTRIMMER_STATUS=$SW_DIR/solid-trimmer.py
#STAR_STATUS=$SW_DIR/STAR
#SUBJUNC_STATUS=/data/app/bin/subjunc
#FEATURECOUNTS_STATUS=$SW_DIR/featureCounts
#KALLISTO_STATUS=$SW_DIR/kallisto

#check all the reference sequences exist and create if necessary
#REFERENCE SEQ AND ANNOTATIONS
MYREF_DIR=$REF_DIR/$ORG/ensembl/
if [ ! -d $MYREF_DIR ] ; then
  mkdir -p $MYREF_DIR
fi

if [ $ORG == "athaliana" ] ; then
  GTFURL="ftp://ftp.ensemblgenomes.org/pub/release-36/plants/gtf/arabidopsis_thaliana/Arabidopsis_thaliana.TAIR10.36.gtf.gz"
  GDNAURL="ftp://ftp.ensemblgenomes.org/pub/release-36/plants/fasta/arabidopsis_thaliana/dna/Arabidopsis_thaliana.TAIR10.dna_sm.toplevel.fa.gz"
  CDNAURL="ftp://ftp.ensemblgenomes.org/pub/release-36/plants/fasta/arabidopsis_thaliana/cdna/Arabidopsis_thaliana.TAIR10.cdna.all.fa.gz"
elif [ $ORG == "celegans" ] ; then
  GTFURL="ftp://ftp.ensembl.org/pub/release-90/gtf/caenorhabditis_elegans/Caenorhabditis_elegans.WBcel235.90.gtf.gz"
  GDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/caenorhabditis_elegans/dna/Caenorhabditis_elegans.WBcel235.dna_sm.toplevel.fa.gz"
  CDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/caenorhabditis_elegans/cdna/Caenorhabditis_elegans.WBcel235.cdna.all.fa.gz"
elif [ $ORG == "dmelanogaster" ] ; then
  GTFURL="ftp://ftp.ensembl.org/pub/release-90/gtf/drosophila_melanogaster/Drosophila_melanogaster.BDGP6.90.gtf.gz"
  GDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/drosophila_melanogaster/dna/Drosophila_melanogaster.BDGP6.dna_sm.toplevel.fa.gz"
  CDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/drosophila_melanogaster/cdna/Drosophila_melanogaster.BDGP6.cdna.all.fa.gz"
elif [ $ORG == "drerio" ] ; then
  GTFURL="ftp://ftp.ensembl.org/pub/release-90/gtf/danio_rerio/Danio_rerio.GRCz10.90.gtf.gz"
  GDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/danio_rerio/dna/Danio_rerio.GRCz10.dna_sm.toplevel.fa.gz"
  CDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/danio_rerio/cdna/Danio_rerio.GRCz10.cdna.all.fa.gz"
elif [ $ORG == "ecoli" ] ; then
  GTFURL="ftp://ftp.ensemblgenomes.org/pub/bacteria/release-36/gtf/bacteria_0_collection/escherichia_coli_str_k_12_substr_mg1655/Escherichia_coli_str_k_12_substr_mg1655.ASM584v2.36.gtf.gz"
  GDNAURL="ftp://ftp.ensemblgenomes.org/pub/bacteria/release-36/fasta/bacteria_0_collection/escherichia_coli_str_k_12_substr_mg1655/dna/Escherichia_coli_str_k_12_substr_mg1655.ASM584v2.dna_sm.chromosome.Chromosome.fa.gz"
  CDNAURL="ftp://ftp.ensemblgenomes.org/pub/bacteria/release-36/fasta/bacteria_0_collection/escherichia_coli_str_k_12_substr_mg1655/cdna/Escherichia_coli_str_k_12_substr_mg1655.ASM584v2.cdna.all.fa.gz"
elif [ $ORG == "hsapiens" ] ; then
  GTFURL="ftp://ftp.ensembl.org/pub/release-90/gtf/homo_sapiens/Homo_sapiens.GRCh38.90.gtf.gz"
  GDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz"
  CDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/homo_sapiens/cdna/Homo_sapiens.GRCh38.cdna.all.fa.gz"
elif [ $ORG == "mmusculus" ] ; then
  GTFURL="ftp://ftp.ensembl.org/pub/release-90/gtf/mus_musculus/Mus_musculus.GRCm38.90.gtf.gz"
  GDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/mus_musculus/dna/Mus_musculus.GRCm38.dna_sm.primary_assembly.fa.gz"
  CDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/mus_musculus/cdna/Mus_musculus.GRCm38.cdna.all.fa.gz"
elif [ $ORG == "rnorvegicus" ] ; then
  GTFURL="ftp://ftp.ensembl.org/pub/release-90/gtf/rattus_norvegicus/Rattus_norvegicus.Rnor_6.0.90.gtf.gz"
  GDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/rattus_norvegicus/dna/Rattus_norvegicus.Rnor_6.0.dna_sm.toplevel.fa.gz"
  CDNAURL="ftp://ftp.ensembl.org/pub/release-90/fasta/rattus_norvegicus/cdna/Rattus_norvegicus.Rnor_6.0.cdna.all.fa.gz"
elif [ $ORG == "scerevisiae" ] ; then
  GTFURL="ftp://ftp.ensemblgenomes.org/pub/release-36/fungi/gtf/saccharomyces_cerevisiae/Saccharomyces_cerevisiae.R64-1-1.36.gtf.gz"
  GDNAURL="ftp://ftp.ensemblgenomes.org/pub/release-36/fungi/fasta/saccharomyces_cerevisiae/dna/Saccharomyces_cerevisiae.R64-1-1.dna_sm.toplevel.fa.gz"
  CDNAURL="ftp://ftp.ensemblgenomes.org/pub/release-36/fungi/fasta/saccharomyces_cerevisiae/cdna/Saccharomyces_cerevisiae.R64-1-1.cdna.all.fa.gz"
fi

# download the necessary reference files
GTF=$MYREF_DIR/$(basename $GTFURL .gz)
if [ -z $GTF ] || [ ! -r $GTF  ] ; then
  cd $MYREF_DIR
  if [ -r $(basename $GTFURL) ] ; then rm $(basename $GTFURL) ; fi
  wget $GTFURL
  gunzip -f $(basename $GTFURL)
  GTF=$MYREF_DIR/$(basename $GTFURL .gz)
  grep -cw gene $GTF > $GTF.cnt
  cd -
fi

GDNA=$MYREF_DIR/$(basename $GDNAURL .gz)
if [ -z $GDNA ] || [ ! -r $GDNA  ] ; then
  cd $MYREF_DIR
  if [ -r $(basename $GDNAURL) ] ; then rm $(basename $GDNAURL) ; fi
  wget $GDNAURL
  gunzip -f $(basename $GDNAURL)
  GDNA=$MYREF_DIR/$(basename $GDNAURL .gz)
  cd -
fi

CDNA=$MYREF_DIR/$(basename $CDNAURL .gz)
if [ -z $CDNA ] || [ ! -r $CDNA  ] ; then
  cd $MYREF_DIR
  if [ -r $(basename $CDNAURL) ] ; then rm $(basename $CDNAURL) ; fi
  wget $CDNAURL
  gunzip -f $(basename $CDNAURL)
  CDNA=$MYREF_DIR/$(basename $CDNAURL .gz)
  grep -c '>' $CDNA > $CDNA.cnt
  cd -
fi

# setup the necessary genome transcriptome indexes
BT2_DIR=$MYREF_DIR/bowtie2
if [ ! -d $BT2_DIR ] ; then
  mkdir -p $BT2_DIR
fi

BT2_REF=$BT2_DIR/$(basename $CDNA)
if [ -z $BT2_REF ] || [ ! -r $BT2_REF  ] ; then
  cd $BT2_DIR ; ln $CDNA .
  #creating bowtie2 index
  bowtie2-build --threads $(nproc) -f $(basename $CDNA) $(basename $CDNA)
  ENS_REFT_BT2=$BT2_DIR/$(basename $CDNA)
  cd -
fi

KAL_DIR=$MYREF_DIR/kallisto
if [ ! -d $KAL_DIR ] ; then
  mkdir -p $KAL_DIR
fi

KAL_REF=$KAL_DIR/$(basename $CDNA).idx
if [ -z $KAL_REF ] || [ ! -r $KAL_REF  ] ; then
  cd $KAL_DIR
  #kallisto index here
  ln $CDNA .
#  for KMER in `seq 11 2 29` ; do
#    kallisto index -i $(basename $CDNA).k$KMER.idx -k $KMER $(basename $CDNA)
#  done
  kallisto index -i $(basename $CDNA).idx $(basename $CDNA)
  for IDX in *idx ; do grep -c '>' $(basename $CDNA) > $IDX.cnt ; done
  KAL_REF=$KAL_DIR/$(basename $CDNA).idx
  cd -
fi

STAR_DIR=$MYREF_DIR/star
if [ ! -d $STAR_DIR ] ; then
  mkdir -p $STAR_DIR
fi

if [ ! -r $STAR_DIR/SA ] || [ ! -r $STAR_DIR/SAindex ] ; then
  echo Creating star index
  cd $STAR_DIR
  ln $GDNA $GTF .
  CWD=`pwd`
  STAR --runMode genomeGenerate \
  --sjdbGTFfile $CWD/$(basename $GTF) \
  --genomeDir $CWD  \
  --genomeFastaFiles $CWD/$(basename $GDNA) \
  --runThreadN `nproc`
  cd -
fi

##########################################################################
# Lets get started
##########################################################################
if [ ! -d $DATA_DIR ] ; then mkdir -p $DATA_DIR ; fi
cd $DATA_DIR
mkdir $SRR ; cp $PIPELINE $SRR ; cd $SRR
echo "Starting $PIPELINE $CFG $URL
  current disk space = $DISK
  free memory = $MEM " | tee -a $SRR.log

##########################################################################
# Check number of attempts
##########################################################################
ATTEMPTS=$SRR.attempts.txt

if [ -r $SRR.attempts.txt ] ; then
  NUM_ATTEMPTS=$(wc -l < $ATTEMPTS)
  if [ $NUM_ATTEMPTS -gt "2" ] ; then
    echo $SRR has already been tried 3 times, skipping
    exit
  fi
fi
DATE=`date +%Y-%m-%d:%H:%M:%S`
echo $PIPELINE $PIPELINE_MD5 $DATE >> $ATTEMPTS

##########################################################################
#Initial disk space check
##########################################################################
DISK=$(df . | awk 'END{print$4}')
if [ $DISK -lt $DISKLIM ] ; then
  echo Error low disk space $DISK available $DISKLIM limit
  exit 1
fi

##########################################################################
echo $SRR check if SRA file exists and download if neccessary
#might let R do this to maintain constant transfers
##########################################################################
if [ ! -f $SRR.sra ] ; then
  #build URL
  BASEURL=ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra
  PFX1=$(echo $SRR | cut -c-3)
  PFX2=$(echo $SRR | cut -c-6)
  URL=anonftp@ftp.ncbi.nlm.nih.gov:sra/sra-instant/reads/ByRun/sra/${PFX1}/${PFX2}/${SRR}/${SRR}.sra
  ID=~/.ascp/aspera-license
  mkdir -p ~/.ascp
cat << EOF > $ID
-----BEGIN DSA PRIVATE KEY-----
MIIBuwIBAAKBgQDkKQHD6m4yIxgjsey6Pny46acZXERsJHy54p/BqXIyYkVOAkEp
KgvT3qTTNmykWWw4ovOP1+Di1c/2FpYcllcTphkWcS8lA7j012mUEecXavXjPPG0
i3t5vtB8xLy33kQ3e9v9/Lwh0xcRfua0d5UfFwopBIAXvJAr3B6raps8+QIVALws
yeqsx3EolCaCVXJf+61ceJppAoGAPoPtEP4yzHG2XtcxCfXab4u9zE6wPz4ePJt0
UTn3fUvnQmJT7i0KVCRr3g2H2OZMWF12y0jUq8QBuZ2so3CHee7W1VmAdbN7Fxc+
cyV9nE6zURqAaPyt2bE+rgM1pP6LQUYxgD3xKdv1ZG+kDIDEf6U3onjcKbmA6ckx
T6GavoACgYEAobapDv5p2foH+cG5K07sIFD9r0RD7uKJnlqjYAXzFc8U76wXKgu6
WXup2ac0Co+RnZp7Hsa9G+E+iJ6poI9pOR08XTdPly4yDULNST4PwlfrbSFT9FVh
zkWfpOvAUc8fkQAhZqv/PE6VhFQ8w03Z8GpqXx7b3NvBR+EfIx368KoCFEyfl0vH
Ta7g6mGwIMXrdTQQ8fZs
-----END DSA PRIVATE KEY-----
EOF
  chmod 700 ~/.ascp
  ascp -l 500m -O 33001 -T -i $ID $URL . \
  || ( echo $SRR failed ascp download | tee -a $SRR.log ; sleep 5 ; exit)
  SRASIZE=$(du ${SRR}.sra)
fi

##########################################################################
echo $SRR Validate the SRA file
##########################################################################
echo $SRR SRAfilesize $SRASIZE | tee -a $SRR.log
md5sum $SRR.sra | tee -a $SRR.log
VALIDATE_SRA=$(vdb-validate $SRR.sra &> /dev/stdout  | head -4 | awk '{print $NF}' | grep -c ok)
if [ $VALIDATE_SRA -eq 4 ] ; then
  echo $SRR.sra file validated | tee -a $SRR.log
else
  echo $SRR.sra md5sums do not match. Deleting and exiting | tee -a $SRR.log
  exit
fi

##########################################################################
echo $SRR diagnose basespace colorspace, single/paired-end and read length
##########################################################################
fastq-dump -X 4000 --split-files $SRR.sra
NUM_FQ=$(ls | grep $SRR | grep -v trimmed.fastq | grep -c fastq$)
if [ $NUM_FQ -eq "1" ] ; then
  ORIG_RDS=SE
  RDS=SE
  echo $SRR is single end | tee -a $SRR.log
elif [ $NUM_FQ -eq "2" ] ; then
  ORIG_RDS=PE
  RDS=PE
  echo $SRR is paired end | tee -a $SRR.log
else
  echo Unable to determine if paired or single end. Quitting. | tee -a $SRR.log
  exit
fi

FQ1=$(ls  | grep $SRR | grep -m1 fastq$)
fastqc $FQ1
FQ1BASE=$(basename $FQ1 .fastq)

#diagnose colorspace or conventional
BASECALL_ENCODING=$(unzip -p ${FQ1BASE}_fastqc ${FQ1BASE}_fastqc/fastqc_data.txt \
| grep 'File type' | cut -f2 | awk '{print $1}')

if [ $BASECALL_ENCODING == "Colorspace" ] ; then
  CSPACE=TRUE
  echo $SRR is colorspace | tee -a $SRR.log
elif [ $BASECALL_ENCODING == "Conventional" ] ; then
  CSPACE=FALSE
  echo $SRR is conventional basespace | tee -a $SRR.log
else
  echo Unable to determine if colorspace or basespace. Quitting. | tee -a $SRR.log
fi

#quality encoding ie Illumina1.9
QUALITY_ENCODING=$(grep -wm1 ^Encoding $SRR.log | cut -f2 | tr -d ' ')

#diagnose read length then
#save entire fastq data to log and delete fastqc zip file and html report
FQ1_LEN=$(unzip -p ${FQ1BASE}_fastqc.zip ${FQ1BASE}_fastqc/fastqc_data.txt \
| grep 'Sequence length' | cut -f2)
echo $SRR read1 length is $FQ1_LEN nt | tee -a $SRR.log
unzip -p ${FQ1BASE}_fastqc.zip ${FQ1BASE}_fastqc/fastqc_data.txt | tee -a $SRR.log
rm ${FQ1BASE}_fastqc.zip ${FQ1BASE}_fastqc.html

FQ1_MIN_LEN=$(sed -n '2~4p' $FQ1 | awk '{print length($1)}' | sort -g | head -1)
FQ1_MEDIAN_LEN=$(sed -n '2~4p' $FQ1 | awk '{print length($1)}' | numaverage -M)
FQ1_MAX_LEN=$(sed -n '2~4p' $FQ1 | awk '{print length($1)}' | sort -gr | head -1)

FQ2_MIN_LEN=NULL
FQ2_MEDIAN_LEN=NULL
FQ2_MAX_LEN=NULL

if [ $RDS == "PE" ] ; then
  FQ2=$(ls  | grep $SRR | grep fastq$ | sed -n 2p)
  fastqc $FQ2
  FQ2BASE=$(basename $FQ2 .fastq)
  FQ2_LEN=$(unzip -p ${FQ2BASE}_fastqc.zip ${FQ2BASE}_fastqc/fastqc_data.txt \
  | grep 'Sequence length' | cut -f2)
  echo $SRR read2 length is $FQ2_LEN nt | tee -a $SRR.log
  unzip -p ${FQ2BASE}_fastqc.zip ${FQ2BASE}_fastqc/fastqc_data.txt | tee -a $SRR.log
  rm ${FQ2BASE}_fastqc.zip ${FQ2BASE}_fastqc.html

  FQ2_MIN_LEN=$(sed -n '2~4p' $FQ2 | awk '{print length($1)}' | sort -g | head -1)
  FQ2_MEDIAN_LEN=$(sed -n '2~4p' $FQ2 | awk '{print length($1)}' | numaverage -M)
  FQ2_MAX_LEN=$(sed -n '2~4p' $FQ2 | awk '{print length($1)}' | sort -gr | head -1)
fi

##########################################################################
echo $SRR if colorspace, then quit
##########################################################################
if [ $CSPACE == "TRUE" ] ; then
  echo Colorspace data is excluded from analysis for now
  exit
fi

##########################################################################
echo $SRR Dump the fastq file
##########################################################################
rm ${SRR}*fastq
if [ $CSPACE == "FALSE" ] ; then
  #$FQDUMP --split-files --defline-qual '+' ${SRR}.sra
  ##try parallelising with fastq-dump
  parallel-fastq-dump --threads 8 --outdir . --split-files --defline-qual + -s ${SRR}.sra
fi

FILESIZE=$(du -s $FQ1 | cut -f1)
echo $SRR file size $FILESIZE | tee -a $SRR.log
rm ${SRR}.sra

if [ "$FILESIZE" -eq 0 ] ; then
  echo $SRR has no reads. Aborting | tee -a $ATTEMPTS ; rm $FQ ; exit
fi

echo $SRR completed basic pipeline successfully | tee -a $SRR.log

##########################################################################
echo $SRR Quality trimming
##########################################################################
if [ $RDS == "SE" ] ; then
  skewer -l 18 -q 10 -k inf -t $THREADS -o $SRR $FQ1
  rm $FQ1
  FQ1=${SRR}-trimmed.fastq

elif [ $RDS == "PE" ] ; then
  skewer -l 18 -q 10 -k inf -t $THREADS -o $SRR $FQ1 $FQ2
  rm $FQ1 $FQ2
  FQ1=${SRR}-trimmed-pair1.fastq
  FQ2=${SRR}-trimmed-pair2.fastq
fi

# check to see that the skewer log was created - if not then there is a problem
if [ ! -f ${SRR}-trimmed.log ] ; then
  echo Skewer failed. Quitting | tee -a $SRR.log
  exit
fi

# get read counts and append skewer log and exit if there are no reads passing QC
READ_CNT_TOTAL=$(grep 'processed; of these:' ${SRR}-trimmed.log | awk '{print $1}')
READ_CNT_AVAIL=$(grep 'available; of these:' ${SRR}-trimmed.log | awk '{print $1}')

if [ -z "$READ_CNT_AVAIL" ] ; then READ_CNT_AVAIL=0 ; fi

cat ${SRR}-trimmed.log >> $SRR.log && rm ${SRR}-trimmed.log
if [ $READ_CNT_AVAIL -eq "0" ] ; then
  echo No reads passed QC. Quitting | tee -a $SRR.log
  exit
else
  echo $READ_CNT_AVAIL reads passed initial QC | tee -a $SRR.log
fi

##########################################################################
echo $SRR adapter diagnosis
##########################################################################
# I use minion to diagnose adapters
# http://wwwdev.ebi.ac.uk/enright-dev/kraken/reaper/src/reaper-latest/doc/minion.html
# If adapter is present higher than the threshold then it will be clipped
# using skewer. One problem is that we don't want the arbitrary threshold to kick
# in for some samples and not others. My idea is to clip any reads over this threshold.
# This will mean that the fastq file needs to be broken up into a part that
# won't be clipped and the one which will be clipped

ADAPTER_THRESHOLD=2
if [ $RDS == "SE" ] ; then
  MINION_LOG=$FQ1.minion.log
  minion search-adapter -i $FQ1 > $MINION_LOG
  ADAPTER=$(head $MINION_LOG | grep -m1 sequence= | cut -d '=' -f2)
  DENSITY=$(head $MINION_LOG | grep -m1 'sequence-density=' | cut -d '=' -f2 | numround -c)
  cat $MINION_LOG | tee -a $SRR.log && rm $MINION_LOG

  if [[ ! -z $DENSITY ]] ; then
    if [ $DENSITY -gt $ADAPTER_THRESHOLD ] ; then
      echo Potential 3prime adapter identified. Now checking if in reference sequence | tee -a $SRR.log
      # Query to see if adapter sequence present in reference
      ADAPTER_REF_CHECK=$(bowtie2 -f -x $BT2_REF -S /dev/stdout <(echo $ADAPTER | sed 's/^/>ADAPTER\n/') 2>>$SRR.log | awk '$1!~/^@/ && $2!=4' | wc -l )

      if [ $ADAPTER_REF_CHECK -eq "0" ] ; then
        echo Adapter seq not found in reference. Now shuffling file before clipping | tee -a $SRR.log
        #FQ1=${SRR}-trimmed.fastq this is the current name
        #shuffling the fq file to remove any tile effects
        paste - - - - < $FQ1 | shuf | tr '\t' '\n' > ${SRR}.fastq
        CLIP_LINE_NUM=$(echo $DENSITY $ADAPTER_THRESHOLD $READ_CNT_AVAIL | awk '{printf "%.0f\n", ($1-$2)/$1*$3*4}' | numround -n 4)
        head -$CLIP_LINE_NUM ${SRR}.fastq | skewer -l 18 -t $THREADS -x $ADAPTER -o $SRR -
        READ_CNT_AVAIL=$(grep 'available; of these:' ${SRR}-trimmed.log | cut -d ' ' -f1)
        if [ -z "$READ_CNT_AVAIL" ] ; then READ_CNT_AVAIL=0 ; fi
        #FQ1 read len min max median
        cat ${SRR}-trimmed.log >> $SRR.log && rm ${SRR}-trimmed.log
        CLIP_LINE_NUM1=$((CLIP_LINE_NUM+1))
        tail -n+$CLIP_LINE_NUM1 ${SRR}.fastq >> ${SRR}-trimmed.fastq && rm ${SRR}.fastq
        minion search-adapter -i ${SRR}-trimmed.fastq | tee -a $SRR.log
      else
        echo Potential adapter found in reference sequence. Continuing without clipping. | tee -a $SRR.log
      fi
    fi
  fi

elif [ $RDS == "PE" ] ; then
  MINION_LOG=$FQ1.minion.log
  minion search-adapter -i $FQ1 > $MINION_LOG
  ADAPTER1=$(head $MINION_LOG | grep -m1 sequence= | cut -d '=' -f2)
  DENSITY1=$(head $MINION_LOG | grep -m1 'sequence-density=' | cut -d '=' -f2 | numround -c)
  cat $MINION_LOG | tee -a $SRR.log && rm $MINION_LOG

  MINION_LOG=$FQ2.minion.log
  minion search-adapter -i $FQ2 > $MINION_LOG
  ADAPTER2=$(head $MINION_LOG | grep -m1 sequence= | cut -d '=' -f2)
  DENSITY2=$(head $MINION_LOG | grep -m1 'sequence-density=' | cut -d '=' -f2 | numround -c)
  cat $MINION_LOG | tee -a $SRR.log && rm $MINION_LOG

  DENSITY=$(echo $DENSITY1 $DENSITY2 | awk '{print ($1+$2)/2}' | numround)

  if [[ ! -z $DENSITY ]] ; then
    if [ $DENSITY -gt $ADAPTER_THRESHOLD ] ; then
      echo Potential 3prime adapter identified. Now checking if in reference sequence | tee -a $SRR.log
      # Query to see if adapter sequence present in reference
      ADAPTER1_REF_CHECK=$($BOWTIE2 -f -x $BT2_REF -S /dev/stdout <(echo $ADAPTER1 | sed 's/^/>ADAPTER\n/') 2>>$SRR.log | awk '$1!~/^@/ && $2!=4' | wc -l )
      ADAPTER2_REF_CHECK=$($BOWTIE2 -f -x $BT2_REF -S /dev/stdout <(echo $ADAPTER2 | sed 's/^/>ADAPTER\n/') 2>>$SRR.log | awk '$1!~/^@/ && $2!=4' | wc -l )

      if [ $ADAPTER1_REF_CHECK -eq "0" -a $ADAPTER2_REF_CHECK -eq "0" ] ; then
        echo Adapter seq not found in reference. Now shuffling file before clipping | tee -a $SRR.log
        paste <(cut -d ' ' -f1 $FQ1) <(cut -d ' ' -f1 $FQ2) | paste - - - - | shuf | awk -F'\t' '{OFS="\n"; print $1,$3,$5,$7 > "R1.fastq"; print $2,$4,$6,$8 > "R2.fastq"}'
        mv R1.fastq ${SRR}_1.tmp.fastq ; mv R2.fastq ${SRR}_2.tmp.fastq
        CLIP_LINE_NUM=$(echo $DENSITY $ADAPTER_THRESHOLD $READ_CNT_AVAIL | awk '{printf "%.0f\n", ($1-$2)/$1*$3*4}' | numround -n 4)
        head -$CLIP_LINE_NUM ${SRR}_1.tmp.fastq > ${SRR}_1.fastq &
        head -$CLIP_LINE_NUM ${SRR}_2.tmp.fastq > ${SRR}_2.fastq ; wait
        skewer -l 18 -t $THREADS -x $ADAPTER1 -y $ADAPTER2 -o $SRR ${SRR}_1.fastq ${SRR}_2.fastq
        READ_CNT_AVAIL=$(grep 'available; of these:' ${SRR}-trimmed.log | cut -d ' ' -f1)
        if [ -z "$READ_CNT_AVAIL" ] ; then READ_CNT_AVAIL=0 ; fi
        cat ${SRR}-trimmed.log >> $SRR.log && rm ${SRR}-trimmed.log
        CLIP_LINE_NUM1=$((CLIP_LINE_NUM+1))
        tail -n+$CLIP_LINE_NUM1 ${SRR}_1.tmp.fastq >> ${SRR}-trimmed-pair1.fastq && rm ${SRR}_1.tmp.fastq
        tail -n+$CLIP_LINE_NUM1 ${SRR}_2.tmp.fastq >> ${SRR}-trimmed-pair2.fastq && rm ${SRR}_2.tmp.fastq
        minion search-adapter -i ${SRR}-trimmed-pair1.fastq | tee -a $SRR.log
        minion search-adapter -i ${SRR}-trimmed-pair2.fastq | tee -a $SRR.log
      else
        echo Potential adapter found in reference sequence. Continuing without clipping. | tee -a $SRR.log
      fi
    fi
  fi
fi

#QcPassRate
QC_PASS_RATE=$(echo $READ_CNT_AVAIL $READ_CNT_TOTAL | awk '{print $1/$2*100"%"}')

FQSIZE=$(du -s $FQ1 | cut -f1)
#cat ${SRR}-trimmed.log >> $SRR.log && rm ${SRR}-trimmed.log
if [ $FQSIZE -eq "0" ] ; then
  echo No reads passed QC. Quitting | tee -a $SRR.log
  exit
fi

##########################################################################
echo $SRR Starting mapping phase
##########################################################################
# need to setup 2 alignments
# -kallisto ensembl
# -star/featurecounts ensembl

#STAR Ensembl
# runs star in gene-wise quant mode and avoid samtools and htseq/featurecounts.
# quant mode can be used with sheared memory if indexed with GTF file
# quantMode also looks like a nice way to diagnose the mapping strand
# Strand information could then be used for kallisto options
# The ReadsPerGene.out.tab file contains count information

# Before running the full mapping procedure for paired end reads, a sample of
# 10000 forward and reverse reads first.

if [ $RDS == "PE" ] ; then
  echo $SRR testing PE reads STAR mapping to Ensembl genome | tee -a $SRR.log
  head $FQ1 $FQ2 ; tail $FQ1 $FQ2

  #test 10k reads FQ1
  head -10000 $FQ1 > test.fq ; head -1000000 $FQ1 | tail -90000 >> test.fq
  RD_CNT=$(sed -n '2~4p' < test.fq | wc -l)
  STAR --runThreadN $THREADS --quantMode GeneCounts --genomeLoad LoadAndKeep \
  --outSAMtype None --genomeDir $STAR_DIR --readFilesIn=test.fq
  MAPPED_CNT=$(cut -f2 ReadsPerGene.out.tab | tail -n +3 | numsum)
  UNMAPPED_CNT=$(cut -f2 ReadsPerGene.out.tab | head -1)
  rm test.fq ReadsPerGene.out.tab
  R1_MAP_RATE=$(echo $MAPPED_CNT $RD_CNT | awk '{print $1/$2*100}' | numround)

  #test 10k reads FQ2
  head -10000 $FQ2 > test.fq ; head -100000 $FQ1 | tail -90000 >> test.fq
  RD_CNT=$(sed '2~4p' test.fq | wc -l)
  STAR --runThreadN $THREADS --quantMode GeneCounts --genomeLoad LoadAndKeep \
  --outSAMtype None --genomeDir $STAR_DIR --readFilesIn=test.fq
  MAPPED_CNT=$(cut -f2 ReadsPerGene.out.tab | tail -n +3 | numsum)
  UNMAPPED_CNT=$(cut -f2 ReadsPerGene.out.tab | head -1)
  rm test.fq ReadsPerGene.out.tab
  R2_MAP_RATE=$(echo $MAPPED_CNT $RD_CNT | awk '{print $1/$2*100}' | numround)

  R1R2_DIFF=$((R1_MAP_RATE-R2_MAP_RATE))

  if [ $R2_MAP_RATE -lt "40" -a $R1R2_DIFF -ge "20" ] ; then
    echo Read2 map rate below 40%, dropping it and using Read1 only | tee -a $SRR.log
    DROP_R2=TRUE
    RDS="SE"
    rm $FQ2
  fi

  R2R1_DIFF=$((R2_MAP_RATE-R1_MAP_RATE))

  if [ $R1_MAP_RATE -lt "40" -a $R2R1_DIFF -ge "20" ] ; then
    echo Read1 map rate below 40%, dropping it and using Read2 only | tee -a $SRR.log
    DROP_R1=TRUE
    RDS="SE"
    mv $FQ2 $FQ1
  fi
fi

## Now performing full alignment
if [ $RDS == "SE" ] ; then
  head $FQ1 ; tail $FQ1
  STAR --runThreadN $THREADS --quantMode GeneCounts --genomeLoad LoadAndKeep \
  --outSAMtype None --genomeDir $STAR_DIR --readFilesIn=$FQ1
elif [ $RDS == "PE" ] ; then
  head $FQ1 $FQ2 ; tail $FQ1 $FQ2  head $FQ1 $FQ2 ; tail $FQ1 $FQ2
  #proper PE mapping
  STAR --runThreadN $THREADS --quantMode GeneCounts --genomeLoad LoadAndKeep \
  --outSAMtype None --genomeDir $STAR_DIR --readFilesIn=$FQ1 $FQ2
fi

#now grab some qc info from the star alignment for later
UNIQ_MAPPED_READS=$(grep 'Uniquely mapped reads number' Log.final.out | awk '{print $NF}')

cat Log.final.out | tee -a $SRR.log && rm Log.final.out Log.out Log.progress.out SJ.out.tab
head -4 ReadsPerGene.out.tab | tee -a $SRR.log
mv ReadsPerGene.out.tab $SRR.se.tsv

##########################################################################
echo $SRR diagnose strandedness now
##########################################################################
# 0=untranded 1=posstrant 2=negstrand
UNSTRANDED_CNT=$(cut -f2 $SRR.se.tsv | tail -n +5 | numsum)
POS_STRAND_CNT=$(cut -f3 $SRR.se.tsv | tail -n +5 | numsum)
NEG_STRAND_CNT=$(cut -f4 $SRR.se.tsv | tail -n +5 | numsum)

echo "UnstrandedReadsAssigned:$UNSTRANDED_CNT \
PositiveStrandReadsAssigned:$POS_STRAND_CNT \
NegativeStrandReadsAssigned:$NEG_STRAND_CNT" | tee -a $SRR.log

if [ $POS_STRAND_CNT -ge "$((NEG_STRAND_CNT*5))" ] ; then
  STRAND=1
  STRANDED=PositiveStrand
  KALLISTO_STRAND_PARAMETER='--fr-stranded'
  echo "Dataset is classified positive stranded" | tee -a $SRR.log
elif [ $NEG_STRAND_CNT -ge "$((POS_STRAND_CNT*5))" ] ; then
  STRAND=2
  STRANDED=NegativeStrand
  KALLISTO_STRAND_PARAMETER='--rf-stranded'
  echo "Dataset is classified negative stranded" | tee -a $SRR.log
else
  STRAND=0
  STRANDED=Unstranded
  KALLISTO_STRAND_PARAMETER=''
  echo "Dataset is classified unstranded" | tee -a $SRR.log
fi
echo KALLISTO_STRAND_PARAMETER=$KALLISTO_STRAND_PARAMETER

#now grab some qc info from the star alignment for later
CUTCOL=$((STRAND+2))
UNMAPPED_CNT=$(cut -f$CUTCOL $SRR.se.tsv | head -1)
MULTIMAPPED_CNT=$(cut -f$CUTCOL $SRR.se.tsv | head -2 | tail -1)
NOFEATURE_CNT=$(cut -f$CUTCOL $SRR.se.tsv | head -3 | tail -1)
AMBIGUOUS_CNT=$(cut -f$CUTCOL $SRR.se.tsv | head -4 | tail -1)
ASSIGNED_CNT=$(cut -f$CUTCOL $SRR.se.tsv | tail -n +5 | numsum)
UNIQ_MAP_RATE=$(echo $UNIQ_MAPPED_READS $READ_CNT_AVAIL | awk '{print $1/$2*100"%"}')
ASSIGNED_RATE=$(echo $ASSIGNED_CNT $READ_CNT_AVAIL | awk '{print $1/$2*100"%"}')

#Now cut out columns to leave us with only the desired strand info
CUTCOL=$((STRAND+2))
cut -f1,$CUTCOL $SRR.se.tsv | tail -n +5 > $SRR.se.tsv.tmp && mv $SRR.se.tsv.tmp $SRR.se.tsv

##########################################################################
echo $SRR checking readlengths now for kmer selection
##########################################################################
## Setting the kallisto kmer correctly is important to getting best accuracy
## Here I measure the median length as well as the 20th percentile
## KMER is set to length at 20th percentile minus 4nt.
MEDIAN_LENGTH=$(sed -n '2~4p' $FQ1 | head -1000000 | awk '{print length}' | sort -n | awk '{all[NR] = $0} END{print all[int(NR*0.50 - 0.5)]}')
D20=$(sed -n '2~4p' $FQ1 | head -1000000 | awk '{print length}' | sort -n | awk '{all[NR] = $0} END{print all[int(NR*0.20 - 0.5)]}')
KMER=$((D20-4))
ADJUST=$(echo $KMER | awk '{print ($1+1)%2}')
KMER=$((KMER-ADJUST))

echo MeadianReadLen=$MEDIAN_LENGTH 20thPercentileLength=$D20 echo kmer=$KMER | tee -a $SRR.log

if [ $KMER -lt "31" ] ; then
  KAL_REF=$(echo $KAL_REF | sed "s#fa.idx#fa.k${KMER}.idx#")
  if [ ! -r $KAL_REF ] ; then
    kallisto index -i $(basename $CDNA).k$KMER.idx -k $KMER $(basename $CDNA)
    for IDX in *idx ; do grep -c '>' $(basename $CDNA) > $IDX.cnt ; done
  fi
fi

##########################################################################
echo $SRR running kallisto now
##########################################################################
#Kallisto Ensembl
if [ $RDS == "SE" ] ; then
  echo $SRR Starting Kallisto single end mapping to ensembl reference transcriptome. kmer=$KMER | tee -a $SRR.log
############################################
# TODO need intelligent frag size specification
###########################################
  kallisto quant $KALLISTO_STRAND_PARAMETER --single -l 100 -s 20 -t $THREADS -o . -i $KAL_REF $FQ1 2>&1 \
  | tee -a $SRR.log && mv abundance.tsv $SRR.ke.tsv
  rm abundance.h5
elif [ $RDS == "PE" ] ; then
  echo $SRR Starting Kallisto paired end mapping to ensembl reference transcriptome | tee -a $SRR.log
  kallisto quant $KALLISTO_STRAND_PARAMETER -t $THREADS -o . -i $KAL_REF $FQ1 $FQ2 2>&1 \
  | tee -a $SRR.log && mv abundance.tsv $SRR.ke.tsv
  rm abundance.h5
fi

# collect qc data
PSEUDOMAPPED_CNT=$(grep 'reads pseudoaligned' $SRR.log | awk '{print $(NF-2)}' | tr -d ',')
PSEUDOMAP_RATE=$(echo $PSEUDOMAPPED_CNT $READ_CNT_AVAIL | awk '{print $1/$2*100"%"}')

# Tidy up files
rm -rf run_info.json ${SRR}-trimmed*.fastq _STARgenome

# Check tsv files
wc -l *tsv | tee -a $SRR.log
head *tsv | tee -a $SRR.log
# Check that tsv files have the right number of entries

SE_NR=$(wc -l < $SRR.se.tsv)
KE_NR=$(wc -l < $SRR.ke.tsv)
SE_CNT=$(cat $GTF.cnt)
KE_CNT=$(cat $CDNA.cnt)

if [ $SE_NR -eq $SE_CNT -a $KE_NR -eq $((KE_CNT+1)) ] ; then

  #now place header on the file for later
  echo $SRR completed mapping pipeline successfully | tee -a $SRR.log
  sed -e "1i${SRR}" $SRR.se.tsv > tmp ; mv tmp  $SRR.se.tsv
  sed -e "1i${SRR}_target_id\t${SRR}_length\t${SRR}_eff_length\t${SRR}_est_counts\t${SRR}_tpm" $SRR.ke.tsv | sed 2d > tmp ; mv tmp $SRR.ke.tsv

  # gzip *tsv
  touch $SRR.finished
else
  echo "$SRR An error occurred. Count file line numbers don't match the reference." | tee -a $SRR.log
  exit
fi

## Collect QC information

## Output .qc file
echo "SequenceFormat:$ORIG_RDS
QualityEncoding:$QUALITY_ENCODING
Read1MinimumLength:$FQ1_MIN_LEN
Read1MedianLength:$FQ1_MEDIAN_LEN
Read1MaxLength:$FQ1_MAX_LEN
Read2MinimumLength:$FQ2_MIN_LEN
Read2MedianLength:$FQ2_MEDIAN_LEN
Read2MaxLength:$FQ2_MAX_LEN
NumReadsTotal:$READ_CNT_TOTAL
NumReadsQcPass:$READ_CNT_AVAIL
QcPassRate:$QC_PASS_RATE
PE_Read1_StarMapRateTest:${R1_MAP_RATE:-NA}
PE_Read2_StarMapRateTest:${R2_MAP_RATE:-NA}
PE_Read1_Excluded:"${DROP_R1:-FALSE}"
PE_Read2_Excluded:"${DROP_R2:-FALSE}"
MappingFormat:$RDS
STAR_UniqMappedReads:$UNIQ_MAPPED_READS
STAR_Strandedness:$STRANDED
STAR_UnmappedReads:$UNMAPPED_CNT
STAR_MultiMappedReads:$MULTIMAPPED_CNT
STAR_NoFeatureReads:$NOFEATURE_CNT
STAR_AmbiguousReads:$AMBIGUOUS_CNT
STAR_AssignedReads:$ASSIGNED_CNT
STAR_UniqMapRate:$UNIQ_MAP_RATE
STAR_AssignRate:$ASSIGNED_RATE
Kallisto_MappedReads:$PSEUDOMAPPED_CNT
Kallisto_MapRate:$PSEUDOMAP_RATE
QC_SUMMARY:${QC_SUMMARY}${REASON}" > $SRR.qc

cd ..
#zip -r $SRR.$ORG.zip $SRR
}
export -f main

#TODO
#-determine parallel jobs
#-allow specific accessions
#-working from within container

if [ $(basename $(pwd)) != "code" ] ; then
  mkdir code && cp ../$0 .
fi

echo Dumping star genomes from memory
for DIR in $(find $(pwd)/../ref/ | grep /ensembl/star$ | sed 's#\/code\/\.\.##' ) ; do
  echo $DIR ; STAR --genomeLoad Remove --genomeDir $DIR
done

MEM=$(free | awk '$1 ~ /Mem:/  {print $2-$3}')
#MEM=$(free | awk 'NR==2{print $4}')
NUM_CPUS=$(nproc)
CPU_SPEED=$(lscpu | grep 'CPU max MHz:' | awk '{print $4}')

IPHASH=$(curl ipinfo.io/ip | md5sum | awk '{print $1}')
if [ $IPHASH == "bbcb41eb861fff23d7882dc61725a6d7" ] ; then
  ACC_URL="192.168.0.99/acc.html"
  ACC_REQUEST="192.168.0.99/cgi-bin/acc.sh"
  SFTP_URL="192.168.0.99"
else
  ACC_URL="http://mdz-analytics.com/acc.html"
  ACC_REQUEST="http://mdz-analytics.com/cgi-bin/acc.sh"
  SFTP_URL="110.22.195.164"
fi



if [ ! -z $MY_ORG ] ; then
  ORG_CHECK=$(echo 'athaliana celegans dmelanogaster drerio ecoli hsapiens mmusculus rnorvegicus scerevisiae' \
  | tr ' ' '\n' | grep -wc "$MY_ORG")
  if [ $ORG_CHECK -ne 1 ] ; then
    echo Organism not specified correctly. Check options and try again.
    exit 1
  fi

  MEM_REQD=$(echo 'athaliana        2853904
celegans        2652204
dmelanogaster   3403644
drerio  14616592
ecoli   1576132
hsapiens        28968508
mmusculus       26069664
rnorvegicus     26913880
scerevisiae     1644684' | grep -w $MY_ORG | awk -v f=$MEM_FACTOR '{print $2*f}')

  if [ $MEM_REQD -gt $MEM ] ; then
    echo Error, analysis of $ORG data requires at least $(echo $MEM_REQD $MEM_FACTOR | awk '{print $1*$2}') kB in RAM, but there is only $MEM available.
    exit 1
  fi
fi

if [ -z $MY_ORG ] ; then
  ORGS=$(echo 'athaliana	2853904
celegans	2652204
dmelanogaster	3403644
drerio	14616592
ecoli	1576132
hsapiens	28968508
mmusculus	26069664
rnorvegicus	26913880
scerevisiae	1644684' | awk -v M=$MEM -v F=$MEM_FACTOR 'M>($2*F)' | sort -k2gr | awk '{print $1}')

  wget -O tmp.html "$ACC_URL"

  if [ $IPHASH != "bbcb41eb861fff23d7882dc61725a6d7" ] ; then
    wget -O tmp.html $(grep 'frame src=' tmp.html | cut -d '"' -f2)
  fi

  #specify organism if it has not already been specified by user
  MY_ORG=$(join -1 1 -2 1 \
  <(grep ORG tmp.html | cut -d '>' -f2 | tr -d ' .' | tr 'A-Z' 'a-z' | tr '()' ' ' | sort -k 1b,1) \
  <(echo $ORGS | tr ' ' '\n' | sort -k 1b,1) | sort -k2gr | awk 'NR==1{print $1}' )

fi

echo $MY_ORG

myfunc(){
MY_ORG=$1
ACC_REQUEST=$2
wget -r -O tmp.html "${ACC_REQUEST}?ORG=${MY_ORG}&Submit"

if [ $IPHASH != "bbcb41eb861fff23d7882dc61725a6d7" ] ; then
  wget -O tmp.html $(grep 'frame src=' tmp.html | cut -d '"' -f2)
fi

ACCESSION=$(grep 'ACCESSION=' tmp.html| cut -d '=' -f2)
STAR --genomeLoad LoadAndExit --genomeDir ../ref/$MY_ORG/ensembl/star >/dev/null
echo $ACCESSION
}
export -f myfunc

count=1
#while [ $count -lt 200 ] ; do
while [ $count -lt 3 ] ; do
  (( count++ ))
  DIR=$(pwd)
  echo "$count"
  ACCESSION=$(myfunc $MY_ORG $ACC_REQUEST)
  ( main "$ACCESSION" "$MY_ORG") && COMPLETE=1 || COMPLETE=0

  if [ "$COMPLETE" -eq "1" ] ; then

    mkdir ~/.ssh

    cat << EOF > ~/.ssh/guestuser
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAyLJ5TihXnb2ATexgYMIkzpHgopCbctWKH8rrPZNN6PALRYjg
1ozfeMFylSvQilFw+6bCe7HlqUQ3e6pS/jHJukEyzbJOEVR4AwuZxxctI4QH00AL
2eDvWvlEOChlxPg8Er5SjPziUXw8Ov3bNLvFHSQ7qlNb/gbKhKvzl6Lk0n6Yzl9C
/eiwzTKjfEKfXAZ51fjyD2fmSFaVleq+t3zviZaGftFtOLKtDA9wXXiosYrBufEf
zixujQF04Hzv+Eg814bjzgkSpZiDyS735NUzu0PCbnXNjZA6QiymisOkhx0J7w3r
vn/gmlYMmeBa5GZZsnnfRBvj0grQIefkLS30RwIDAQABAoIBAHVdUWzwUJRxPjfT
dGUBA689RaUrdYxI7hY7fyeqHdSLk7vdGMa+6OxgDBbJ4ZERoUW4tmDJnqlGuD98
Uj5OdU6TVBdQHzEpOWlmfk4b8oyjaEQUXxnR3YdQ36ELlsAB/ndjjzjdpafLRBmn
XGpRKCsrhizLxK8f34yIVdImMzQYQ7Enki003AgmEWZ/hZmOJtbXWHq/MIGk67Gq
rD3UJL+w0OVgQMYdD57CNBlpQIVDu4Z2C7NPLW/n2DiatzZ+7wOSWfc3I2Gu1E5o
/YV84Pa0dzwpCnBSNuWtrieSHgF96R2rBk/2slN/q1MV0XAFxFqnup1A/YpmdCI2
04+Q5vkCgYEA/IzR+nGquL/bJevGhtanMMxGMVSZJuCYGQU33R/WrWbDz1AJqPtd
/rQlFWcfkK4hpcZdGNIoVkH3aa/mfhMfGx1DEScxzoFaPEj2vKBDldPYyMW7owVH
ByPP0EiWwmERi7Ds6o/F325b2w0c1+waOTbA1eD9/dUZzExgVeBYes0CgYEAy3BS
TJ+5/wu0XkQi2qqUck4hdB6VrmLujTGcT6MmOyncGL0Y6SR9cvf51UpbPsCQpCEm
bOvRia/3wq9ovKIP3Zx22+SFSeu0bGeYo+i2ofzxl4XzZo3JIMpJtRXahn4BAH5E
PzXd/Hs4AkCgnQB3HXDyp3FSDFxC0V7/jvO+U2MCgYEAioAb47IUg09MOuarsGTl
ucA9Om5/sy92mjofYdhFHkF+XyIwughoivd2Yt90Ex87+rLneWY/ktaIfeBmknug
EnmgvzZ0fSC5QNhu4BEwH2nXuHugJI4PXt4H6Nz2ONGNEsPLmfOQ+7CFFYOCbvPf
icL6TBEgmeUVSdIU/uOTAn0CgYAN6OsnpBAymRlHDL+ZVep6ek8dQm4Xk1oeO1Ml
utEFYJJU+rD2V/Ff6AakB8Z/XulE36Nh9SnJkUeOfzHZG/ebvnP+Cvz2FfCrLNYp
9uJt5v6ZzqXa0Dz9SfeKMylS4tCsuPVvoP5BoictOEADHCII2E0vF7d1cuV6rVUp
8A6GYwKBgQCc8T4sr/wF/BKkk+kCBUpsYibqIxnTw7Rjl/+gUJL5IR3ynmWuJkUt
Qzab+/WnlQMuslmCLxXXOijq5lEDJLJ0m9hZ0sdC+j13jsTCEOnyj/XJ3VgLKifP
8itVEOnDffxs+RKeaXWhPiSll/wp6SlSuIdI2VpYMd15LtmkSkZSYg==
-----END RSA PRIVATE KEY-----
EOF

    cat << EOF > ~/.ssh/guestuser.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIsnlOKFedvYBN7GBgwiTOkeCikJty1Yofyus9k03o8AtFiODWjN94wXKVK9CKUXD7psJ7seWpRDd7qlL+Mcm6QTLNsk4RVHgDC5nHFy0jhAfTQAvZ4O9a+UQ4KGXE+DwSvlKM/OJRfDw6/ds0u8UdJDuqU1v+BsqEq/OXouTSfpjOX0L96LDNMqN8Qp9cBnnV+PIPZ+ZIVpWV6r63fO+JloZ+0W04sq0MD3BdeKixisG58R/OLG6NAXTgfO/4SDzXhuPOCRKlmIPJLvfk1TO7Q8Judc2NkDpCLKaKw6SHHQnvDeu+f+CaVgyZ4FrkZlmyed9EG+PSCtAh5+QtLfRH mdz@opti
EOF

    chmod -R 700 ~/.ssh

    cd ../data/$MY_ORG
    zip -r $ACCESSION.$MY_ORG.zip $ACCESSION
    sftp -i ~/.ssh/guestuser guestuser@$SFTP_URL << EOF
put $ACCESSION.$MY_ORG.zip
EOF

#rm -rf .ssh
    cd $DIR
  fi
done
