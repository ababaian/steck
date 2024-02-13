#==========================================================
# LOGAN-BASE CONTAINER ====================================
#==========================================================
# Docker Base: amazon linux2
FROM amazonlinux:2 AS logan-base

## Build/test container for logan
# sudo yum install -y docker git
# sudo service docker start
# git clone https://github.com/ababaian/logan.git; cd logan
# sudo docker build -t logan-base:0 -t logan-base:latest -f docker/Dockerfile .
# sudo docker run --rm --entrypoint /bin/bash -it logan-align:0

#==========================================================
# Container Meta-data =====================================
#==========================================================
# Container Information
ARG PROJECT='logan'
ARG TYPE='base'
ARG VERSION='0.0.1'

# Additional Metadata
LABEL container.base.image="amazonlinux:2"
LABEL project.name=${PROJECT}
LABEL project.website="https://github.com/ababaian/logan"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="logan-base image"
LABEL software.license="GPLv3"
LABEL tags="aws-cli, INFERNAL"

# Software versions
ENV INFERNALVERSION='1.1.4'

#==========================================================
# Dependencies ============================================
#==========================================================
# For development only
RUN yum -y install vim htop

# Update Core
RUN yum -y update
RUN yum -y install tar wget gzip which sudo shadow-utils \
           util-linux byacc

# Python3
RUN yum -y install python3 python3-devel
RUN alias python=python3
RUN curl -O https://bootstrap.pypa.io/get-pip.py &&\
    python3 get-pip.py &&\
    rm get-pip.py

# AWS S3
RUN pip install boto3 awscli
RUN yum -y install jq

# Libraries for htslib
#RUN yum -y install gcc make \
#    unzip bzip2 bzip2-devel xz-devel zlib-devel \
#    curl-devel openssl-devel \
#    ncurses-devel

#==========================================================
# Install Software ========================================
#==========================================================
# INFERNAL ======================================
# cmsearch is required alone (in theory)
# build from source
RUN wget http://eddylab.org/infernal/infernal-"$INFERNALVERSION"-linux-intel-gcc.tar.gz &&\
  tar -xvf infernal* &&\
  cd infernal* &&\
  bash configure && make && make install &&\
  cd ..

# binaries copy (does not work)
#  chmod 755 infernal*/binaries/* &&\
#  cp infernal*/binaries/* /usr/local/bin/ &&\
#  rm -rf infernal*


#==========================================================
# logan Initialize =====================================
#==========================================================
# Set working directory to /home/logan
# Create a logan user fro use of FUSE / fusera
RUN adduser logan
ARG BASEDIR=/home/logan
ENV BASEDIR=/home/logan
RUN echo 'alias logan="sudo -u logan"' >> /root/.bashrc

WORKDIR /home/logan

# Increase the default chunksize for `aws s3 cp`.  By default it is 8MB,
# which results in a very high number of PUT and POST requests.  These
# numbers have NOT been experimented on, but chosen to be just below the
# max size for a single-part upload (5GB).  I haven't pushed it higher
# because I don't want to test the edge cases where a filesize is around
# the part limit.
RUN aws configure set default.s3.multipart_threshold 4GB \
 && aws configure set default.s3.multipart_chunksize 4GB

#==========================================================
# ENTRYPOINT ==============================================
#==========================================================
# N/A
