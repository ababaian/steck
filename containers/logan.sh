#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# logan-base.sh
# =====================================
set -eu
#
# Base: logan-base (0.0.1)
# Amazon Linux 2 with Docker
# AMI : aami-0fdf24f2ce3c33243
# login: ec2-user@<ipv4>
#

# Test cmd: ./logan-base.sh 
PIPE_VERSION="0.0.1"
AMI_VERSION='ami-0fdf24f2ce3c33243'
CONTAINER_VERSION='logan-base:0.0.1'

# Usage
function usage {
  echo ""
  echo "Usage: docker run logan:latest [OPTIONS]"
  echo ""
  echo "    -h    Show this help/usage message"
  echo ""
  echo "    Required Fields"
  echo "    -q    Query database file. '.cm' (infernal)"
  echo "    -f    Fasta search file. S3 bucket path for input contigs [s3://bucket/contigs.fa]"
  echo ""
  echo "    Alignment Parameters"
  echo "    -a    Alignment software ['infernal' (default) | 'diamond' (NA) | 'rdrp' (NA) ]"
  echo "    -n    parallel CPU threads to use where applicable  [1]"
  echo ""
  echo "    AWS / S3 Bucket parameters"
  echo ""
  echo "    Output options"
  echo "    -v    Flag. Verbose output"
  echo "    -b    Base directory in container [/home/logan/]"
  echo "    -3    S3 Bucket Directory to output output"
  echo "    -o    <output_prefix> [Defaults]"
  echo ""
  echo "    Outputs Uploaded to s3: "
  echo "          <output_prefix>.fq.xxxx ... <output_prefix>.fq.yyyy"
  echo ""
  echo "ex: sudo docker run logan -q dvr5.cm -f mdv.fa -o utest"
  false
  exit 1
}

# PARSE INPUT =============================================
# Generate random alpha-numeric for run-id
RUNID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1 )

# Set Default Parameters
# Alignment files
FA='mdv.fa'

# Output options -do
BASEDIR='/home/logan'
S3=''
OUTNAME='test'

# Aligner Options
QUERY='dvr5.cm'
ALIGNER='infernal'
THREADS='1'

# Options
VERBOSE='FALSE'

while getopts q:f:a:n:b:3:o:vh FLAG; do
  case $FLAG in
    # Search Files  -----------
    q)
      QUERY=$OPTARG
      ;;
    f)
      FA=$OPTARG
      ;;
    # Aligner Options ---------
    a)
      ALIGNER=$OPTARG
      ;;
    n)
      THREADS=$OPTARG
      ;;
    # output options -------
    b)
      BASEDIR=$OPTARG
      ;;
    o)
      OUTNAME=$OPTARG
      ;;
    3)
      S3=$OPTARG
      ;;
    v)
      VERBOSE='TRUE'
      ;;
    h)  #show help ----------
      usage
      ;;
    \?) #unrecognized option - show help
      echo "Input parameter not recognized"
      usage
      ;;
  esac
done


# RUN INFERNAL ============================================
echo "=========== LOGAN ==========="
echo ""
echo "Query:  $QUERY"
echo "Fasta:  $FA"
echo "Tool:   $ALIGNER"
echo "Thread: $THREADS"
echo "Output: $OUTNAME"
echo ""

if [[ $VERBOSE == 'TRUE' ]]
then 
  # run INFERNAL
  /usr/bin/time -v cmsearch \
    -o /dev/null \
    --cpu $THREADS -Z 1000 \
    --tblout $OUTNAME.tblout \
    $QUERY \
    $FA

  # Cat output        
  cat $OUTNAME.tblout
else
    cmsearch \
    -o /dev/null \
    --cpu $THREADS -Z 1000 \
    --tblout $OUTNAME.tblout \
    $QUERY \
    $FA
fi

# If an S3 Bucket is provided, upload the output to S3
# Else print to STDOUT
if [ "$S3" == "s3://*" ]
then
	#aws s3 cp --only-show-errors $OUTNAME.tblout $S3
  echo "uploading output:"
  echo "  aws s3 cp $OUTNAME.tblout $S3"

	aws s3 cp $OUTNAME.tblout $S3
else
	cat $OUTNAME.tblout
fi

# RUN UPLOAD ==============================================
#aws s3 cp --only-show-errors $SRA.$BL_N.bam s3://$S3_BUCKET/bam-blocks/$SRA/
