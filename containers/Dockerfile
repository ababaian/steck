#==========================================================
# LOGAN-BASE CONTAINER ====================================
#==========================================================
# Docker Base: amazon linux2
FROM amazonlinux:2 AS logan_base

## Build/test container for logan
# sudo yum install -y docker git
# sudo service docker start
# git clone https://github.com/ababaian/logan.git; cd logan
# sudo docker build ./ -t logan:latest -t logan:dev -t logan
## Interactive
# sudo docker run --rm --entrypoint /bin/bash -it logan:latest
## Test script
# sudo docker run logan

## Build/push container for logan ECR
## aws ecr-public get-login-password --region us-east-1 \
##   | sudo docker login --username AWS \
##       --password-stdin public.ecr.aws/q4q7t4w2
##
## sudo docker build ./ -t logan:latest -t logan:dev -t logan
## sudo docker tag logan:latest public.ecr.aws/q4q7t4w2/logan:latest
##
## sudo docker push public.ecr.aws/q4q7t4w2/logan:latest
##

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
FROM amazonlinux:2 AS logan

# Container Information
ARG PROJECT='logan'
ARG TYPE='runtime'
ARG VERSION='0.0.1'

# Additional Metadata
LABEL container.base.image="amazonlinux:2"
LABEL project.name=${PROJECT}
LABEL project.website="https://github.com/ababaian/logan"
LABEL container.type=${TYPE}
LABEL container.version=${VERSION}
LABEL container.description="logan-runtime image"
LABEL software.license="GPLv3"
LABEL tags="aws-cli, INFERNAL"

#==========================================================
# logan Initialize ========================================
#==========================================================
# Set Variables
ARG BASEDIR=/home/logan
ENV BASEDIR=/home/logan
WORKDIR /home/logan

# Set working directory to /home/logan
# Create a logan user fro use of FUSE / fusera
RUN yum -y install time gzip unzip \
                   wget curl sudo \
                   shadow-utils &&\
    adduser logan &&\
    echo 'alias logan="sudo -u logan"' >> /root/.bashrc &&\
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" &&\
    unzip awscliv2.zip &&\
    ./aws/install

# INFERNAL
COPY --from=logan_base /usr/local/bin/cmsearch /usr/local/bin/

# Copy Scripts
COPY logan.sh /home/logan/
COPY dvr5.cm  /home/logan/
COPY mdv.fa   /home/logan/

# Increase the default chunksize for `aws s3 cp`.  By default it is 8MB,
# which results in a very high number of PUT and POST requests.  These
# numbers have NOT been experimented on, but chosen to be just below the
# max size for a single-part upload (5GB).  I haven't pushed it higher
# because I don't want to test the edge cases where a filesize is around
# the part limit.
# Configure AWS Locally
RUN chmod 755 logan.sh  \
 && aws configure set default.region us-east-1 \
 && aws configure set default.s3.multipart_threshold 4GB \
 && aws configure set default.s3.multipart_chunksize 4GB
#==========================================================
# ENTRYPOINT ==============================================
#==========================================================
ENTRYPOINT ["./logan.sh"]
