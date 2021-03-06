#!/bin/bash
# used as a "bootstrap" script for an EMR cluster
# installs software - in a version agnostic manner where possible
# ASSUMPTION: only one version of each software package is available locally

set -e
set -o pipefail

#sudo yum update -y --skip-broken

sudo mkdir /app
sudo chown hadoop /app # We need this as making directory in / will require sudo usage and thus the owner won't be hadoop anymore
pushd /app > /dev/null

aws s3 cp $1 . --recursive

# Install STAR and its' dependencies
sudo yum install make gcc-c++ glibc-static -y

# STAR
tar -xzf STAR*.tar.gz
star_path=$( find . -name "STAR"|grep -E "/Linux_x86_64/" )
# symbolic link to the STAR directory (rather than to the executable itself)
ln -s ${star_path%STAR} STAR

# Install subread (featureCount)
tar -xzf subread*.tar.gz
fc=$( find -name "featureCounts"|grep bin )
sr_path=${fc%featureCounts}
ln -s $sr_path subread

# Install HISAT2
unzip hisat2*.zip
hisat_dir=$( find . -maxdepth 1 -type d -name "hisat2*")
ln -s $hisat_dir hisat

# Install HTSeq
sudo pip install pysam
sudo pip install htseq

# Install samtools
sudo yum install zlib-devel ncurses-devel ncurses bzip2-devel xz-devel -y --skip-broken
tar -xjf samtools*.tar.bz2
sam_dir=$( find . -maxdepth 1 -type d -name "samtools*" )
pushd $sam_dir > /dev/null
make
sudo make install
popd > /dev/null
ln -s $sam_dir samtools

# Install htslib
hts_dir=$( find $sam_dir -maxdepth 1 -type d -name "htslib-*" )
pushd $hts_dir > /dev/null
make
sudo make install
popd > /dev/null

# Install picard_tools
# Note: latest version of picard_tools come as a jar file. We do not need to do anything.
mkdir picard-tool
mv picard.jar picard-tool/

# Install stringtie
tar -xzf stringtie*.tar.gz
stringtie_dir=$( find . -maxdepth 1 -type d -name "stringtie*")
ln -s $stringtie_dir stringtie

# Install scallop
tar -xzf scallop-*_linux_x86_64.tar.gz
scallop_dir=$( find . -maxdepth 1 -type d -name "scallop*" )
ln -s $scallop_dir scallop

# Install gffcompare
tar -xzf gffcompare*.tar.gz
gffcompare_dir=$( find . -maxdepth 1 -type d -name "gffcompare*")
ln -s $gffcompare_dir gffcompare

# INSTALL CUSTOM PRE-PROCESSING TOOLS BELOW

# trim galore
tg=trim_galore
unzip trim_galore*.zip
tg_path=$( find . -name $tg )
ln -s $tg_path $tg

# trimmomatic
unzip Trimmomatic*.zip
tm=$( find . -name trimmomatic*.jar )
ln -s $tm ${tm##*/}

# prinseq
ps=prinseq-lite.pl
tar -xzf prinseq-lite*.tar.gz
ps_path=$( find . -name "$ps" )
ln -s $ps_path $ps

# install cutadapt
sudo pip install cutadapt

# -------------------------------------------------------------
# no longer in /mnt/app
popd > /dev/null

# Install python dependencies for framework
sudo pip install pandas boto3 ascii_graph pysam
sudo python3 -m pip install pandas boto3 ascii_graph pysam

# install htop
sudo yum install htop -y
