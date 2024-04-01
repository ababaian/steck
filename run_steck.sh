#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# run_steck.sh
# =====================================
set -eu
#
# Base: steck-base (0.0.1)
# Amazon Linux 2 with Docker
# AMI : aami-0fdf24f2ce3c33243
# login: ec2-user@<ipv4>
#

# Run parameter list file
RUNLIST='runs/klahanie.runlist'

# Steck Job Parameters
JNAME='steck-testJob'           # job-name
JDEF='steck-job-ec2'            # job-definition
JQUE='steck-queue-ec2'          # job-queue
TOUT='7200'                     # job-timeout

# Parameterization of inputs
POUTNAME="tmp-output"           # placeholder
PFA='mdv.fa'                    # ''
PS3='s3://steck-tmp/'           # ''


# Iterate through the TOPO (input file)
# and run a job for each parameter-line
while read line;
do
  # Read Output name (SRR) from testPitch file (field 1)
  POUTNAME=$(echo $line | cut -f1 -d' ' - )
  # Read Fasta S3 file from testPitch (field 2)
  PFA=$(echo $line | cut -f2 -d' ' - )
  # Job-name (field 3)
  JNAME=klahanie-$(echo $line | cut -f3 -d' ' - )

  # Submit Batch Job
  aws batch submit-job \
    --job-name $JNAME \
    --job-definition $JDEF  \
    --job-queue  $JQUE \
    --timeout attemptDurationSeconds="$TOUT" \
    --parameters outname="$POUTNAME",fa="$PFA",s3="$PS3" \
    --container-overrides '{
      "command": [
        "-n", "1",
        "-o", "Ref::outname",
        "-f", "Ref::fa",
        "-3", "Ref::s3"
      ],
      "resourceRequirements": [
      {
        "value": "1",
        "type": "VCPU"
      },
      {
        "value": "1500",
        "type": "MEMORY"
      } ]
    }' &
    sleep 0.05 # limit to 20 transactions per second

done < $TOPO