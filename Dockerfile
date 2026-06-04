FROM ubuntu:24.04 AS build

LABEL authors="andrea.talenti@ed.ac.uk" \
      description="Docker image containing base requirements for ADMIXBoots pipelines"

# Install the updates first
RUN apt-get update && \
  apt-get install -y gcc g++ git make wget unzip zlib1g-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install evalAdmix
RUN git clone https://github.com/GenisGE/evalAdmix.git && \
  cd evalAdmix && \
  make && \
  cp evalAdmix /opt/

# Install CLUMPP
RUN wget https://rosenberglab.stanford.edu/software/CLUMPP_Linux64.1.1.2.tar.gz && \
  tar -xvzf CLUMPP_Linux64.1.1.2.tar.gz && \
  mv CLUMPP_Linux64.1.1.2/CLUMPP /opt/

# Install admixture
RUN wget https://dalexander.github.io/admixture/binaries/admixture_linux-1.4.0.tar.gz && \
  tar -xvzf admixture_linux-1.4.0.tar.gz && \
  mv admixture_linux-1.4.0/admixture /opt/

# Install plink
RUN wget https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20250819.zip && \
  unzip plink_linux_x86_64_20250819.zip && \
  mv plink /opt/

# The runtime-stage image; we can use Debian as the
# base image since the Conda env also includes Python
# for us.
FROM rocker/tidyverse:4.4 AS runtime

# Install procps in debian to make it compatible with reporting
RUN apt-get update && \
  apt install -y git procps file wget python3 python3-pip && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy opt files from build stage and make them executable
COPY --from=build /opt/ /opt
RUN chmod +x /opt/*

# Export opt to path
ENV PATH="/opt:${PATH}"

# Install the python packages
RUN pip install --break-system-packages --no-cache-dir numpy pandas 
RUN pip install --break-system-packages --no-cache-dir adamixture
RUN pip install --break-system-packages --no-cache-dir clumppling
RUN pip install --break-system-packages --no-cache-dir kalignedoscope

# Then install the R packages
RUN install2.r --error reshape2
RUN install2.r --error forcats
RUN install2.r --error ggthemes
RUN install2.r --error patchwork
RUN install2.r --error stringi

# Make python3 into python
RUN apt-get update && \
  apt install -y python-is-python3 && \
  apt remove -y git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Activate the right shell
SHELL ["/bin/bash", "-c"]
