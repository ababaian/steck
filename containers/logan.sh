#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# logan.sh
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
  echo "    -f    Fasta search file or S3 path for contig file [s3://bucket/contigs.fa]"
  echo ""
  echo "    Alignment Parameters"
  echo "    -a    Alignment software ['infernal' (default) | 'diamond' (NA) | 'rdrp' (NA) ]"
  echo "    -n    parallel CPU threads to use where applicable  [1]"
  echo ""
  echo "    AWS / S3 Bucket parameters"
  echo "    -A    Flag. Imports ~/.aws/credentials.csv file for container AWS access."
  echo "                requires mounting (-v) CSV file at Docker Run (see usage below)"
  echo "          Not required if using Cloud/IAM"
  echo ""
  echo "    Output options"
  echo "    -v    Flag. Verbose output"
  echo "    -b    Base directory in container [/home/logan/]"
  echo "    -3    [s3://logan-steck/] S3 Bucket Directory to upload output into"
  echo "    -o    <output_prefix> [Defaults]"
  echo ""
  echo "    Outputs Uploaded to s3: "
  echo "          <output_prefix>.fq.xxxx ... <output_prefix>.fq.yyyy"
  echo ""
  echo 'ex: sudo docker run logan -v $HOME/.aws/logan:/home/logan/aws.csv -A -q dvr5.cm -f mdv.fa -o utest'
  false
  exit 1
}

# PARSE INPUT =============================================
# Generate random alpha-numeric for run-id
#RUNID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1 )

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
AWSCRED='FALSE'
VERBOSE='FALSE'

# Check if Array Job
if [[ -z "${AWS_BATCH_JOB_ARRAY_INDEX-}" ]]
then
  AWS_BATCH_JOB_ARRAY_INDEX='n/a'
fi

while getopts q:f:a:n:b:3:o:vAh FLAG; do
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
    A)
      AWSCRED='TRUE'
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

# INIT AWS ================================================
# When running Docker Container locally, the credentials to
# use AWS need to be mounted into the container from the
# local filesystem.
# Ensure "User Name" field is present and set to `default`
# in the aws credentials.csv file
# usage: 
# docker run logan -v $HOME/.aws/logan:/home/logan/aws.csv
if [[ $AWSCRED == 'TRUE' ]]
then
  aws configure import --csv file:///home/logan/aws.csv
fi

# RUN INFERNAL ============================================
echo "=========== LOGAN ==========="
echo ""
echo "Query:  $QUERY"
echo "Fasta:  $FA"
echo "Tool:   $ALIGNER"
echo "Thread: $THREADS"
echo "Output: $OUTNAME"
echo "BArray: $AWS_BATCH_JOB_ARRAY_INDEX"
echo ""

# Test for internet/s3 connectivity
if [[ $VERBOSE == 'TRUE' ]]
then 
  echo 'Test Internet connectivity'
  wget https://serratus-public.s3.amazonaws.com/var/aws-test-token.jpg

  echo 'Test AWS/S3 permissions '
  aws s3 cp s3://serratus-public/var/aws-test-token.jpg ./
fi

if [[ $FA == s3://* ]]
then
  # NOTE: Consider implementing Mountpoint
  # https://github.com/awslabs/mountpoint-s3/tree/main
  echo "S3 FA file provided"
  aws s3 cp $FA $OUTNAME.fa
  FA="$OUTNAME.fa"
else
  echo "Local FA file provided"
fi

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

# If no output S3 Bucket is provided, print to STDOUT
# Else upload the output to S3 bucket-dir
if [[ $S3 == '' ]]
then
  # Output 
  cat $OUTNAME.tblout
else
	#aws s3 cp --only-show-errors $OUTNAME.tblout $S3
  echo "uploading output:"
  echo "  aws s3 cp $OUTNAME.tblout $S3"
	aws s3 cp $OUTNAME.tblout $S3
fi

# RUN UPLOAD ==============================================
#aws s3 cp --only-show-errors $SRA.$BL_N.bam s3://$S3_BUCKET/bam-blocks/$SRA/
