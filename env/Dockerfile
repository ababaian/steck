#==========================================================
# STECK-BASE CONTAINER ====================================
#==========================================================
# Docker Base: amazon linux2
FROM amazonlinux:2 AS steck_base

## Build/test container for steck
# sudo yum install -y docker git
# sudo service docker start
# git clone https://github.com/ababaian/steck.git; cd steck
# sudo docker build ./ -t steck:latest -t steck:dev -t steck
## Interactive
# sudo docker run --rm --entrypoint /bin/bash -it steck:latest
## Test script
# sudo docker run steck

## Build/push container for steck ECR
## aws ecr-public get-login-password --region us-east-1 \
##   | sudo docker login --username AWS \
##       --password-stdin public.ecr.aws/q4q7t4w2
##
## sudo docker build ./ -t steck:latest -t steck:dev -t steck
## sudo docker tag steck:latest public.ecr.aws/q4q7t4w2/steck:latest
##
## sudo docker push public.ecr.aws/q4q7t4w2/steck:latest
##

#==========================================================
# Container Meta-data =====================================
#==========================================================
# Container Information
ARG PROJECT='steck'
ARG TYPE='base'
ARG VERSION='0.0.1'

# Additional Metadata
LABEL container.base.image="amazonlinux:2"
LABEL project.name=${PROJECT}
LABEL project.website="https://github.com/ababaian/steck"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="steck-base image"
LABEL software.license="GPLv3"
LABEL tags="aws-cli, INFERNAL"

# Software versions
ENV INFERNALVERSION='1.1.5'

#==========================================================
# Dependencies ============================================
#==========================================================
# For development
RUN yum -y install vim htop time

# Update Core
RUN yum -y update
RUN yum -y install tar wget gzip \
           which sudo shadow-utils \
           util-linux byacc \
           glibc groff less jq

# Python3
RUN yum -y install python3 python3-devel
RUN alias python=python3
RUN curl -O https://bootstrap.pypa.io/get-pip.py &&\
    python3 get-pip.py &&\
    rm get-pip.py

# Libraries for INFERNAL
RUN yum -y install gcc make \
    unzip bzip2 bzip2-devel xz-devel zlib-devel \
    curl-devel openssl-devel \
    ncurses-devel

# AWS S3
RUN pip install boto3
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip &&\
    ./aws/install

#==========================================================
# Install Software ========================================
#==========================================================
# INFERNAL ======================================
# cmsearch is required alone (in theory)
# build from source
RUN wget http://eddylab.org/infernal/infernal-"$INFERNALVERSION"-linux-intel-gcc.tar.gz &&\
  tar -xvf infernal* &&\
  cd infernal* &&\
  bash configure --prefix /usr/local/ && make && make install &&\
  cd ..

#==========================================================
# Build Runtime ===========================================
#==========================================================
FROM amazonlinux:2 AS steck

# Container Information
ARG PROJECT='steck'
ARG TYPE='runtime'
ARG VERSION='0.0.1'

# Additional Metadata
LABEL container.base.image="amazonlinux:2"
LABEL project.name=${PROJECT}
LABEL project.website="https://github.com/ababaian/steck"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="steck-runtime image"
LABEL software.license="GPLv3"
LABEL tags="aws-cli, INFERNAL"

#==========================================================
# steck Initialize ========================================
#==========================================================
# Set Variables
ARG BASEDIR=/home/steck
ENV BASEDIR=/home/steck
WORKDIR /home/steck

# Set working directory to /home/steck
# Create a steck user fro use of FUSE / fusera
RUN yum -y install time gzip unzip \
                   wget curl sudo \
                   shadow-utils &&\
    adduser steck &&\
    echo 'alias steck="sudo -u steck"' >> /root/.bashrc &&\
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip &&\
    ./aws/install

# INFERNAL
COPY --from=steck_base /usr/local/bin/cmsearch /usr/local/bin/

# Copy Scripts
COPY steck.sh /home/steck/
COPY dvr5.cm  /home/steck/
COPY mdv.fa   /home/steck/

# Increase the default chunksize for `aws s3 cp`.  By default it is 8MB,
# which results in a very high number of PUT and POST requests.  These
# numbers have NOT been experimented on, but chosen to be just below the
# max size for a single-part upload (5GB).  I haven't pushed it higher
# because I don't want to test the edge cases where a filesize is around
# the part limit.
# Configure AWS Locally
RUN chmod 755 steck.sh  \
 && aws configure set default.region us-east-1 \
 && aws configure set default.s3.multipart_threshold 4GB \
 && aws configure set default.s3.multipart_chunksize 4GB
#==========================================================
# ENTRYPOINT ==============================================
#==========================================================
ENTRYPOINT ["./steck.sh"]
