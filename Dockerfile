FROM alpine:latest
WORKDIR /app

# Add scripts
ADD ./bin/AdmixPermute /usr/local/bin/
ADD ./bin/arrange /usr/local/bin/ 
ADD ./bin/BestBootstrappedK /usr/local/bin/
ADD ./bin/BsTpedTmap /usr/local/bin/
ADD ./bin/MakeBootstrapLists /usr/local/bin/

# Install ubuntu dependencies
RUN apk update \                                                                                                                                                                                                                        
  &&   apk add ca-certificates wget \                                                                                                                                                                                                      
  &&   update-ca-certificates

# Install python, R and R packages
RUN apk add wget python R && rm -rf /var/cache/apk/*
RUN Rscript -e 'install.packages("httr", repos="https://cloud.r-project.org")'
RUN Rscript -e 'install.packages("rvest", repos="https://cloud.r-project.org")'
RUN Rscript -e 'install.packages("xml2", repos="https://cloud.r-project.org")'
RUN Rscript -e 'install.packages("tidyverse", repos="https://cloud.r-project.org")'

# Install admixture v1.3
RUN wget http://dalexander.github.io/admixture/binaries/admixture_linux-1.3.0.tar.gz && \
    tar xvfz admixture_linux-1.3.0.tar.gz && \
    mv ./dist/admixture_linux-1.3.0/admixture /usr/local/bin && \
    chmod a+x /usr/local/bin/admixture && \
    rm -rf ./dist admixture_linux-1.3.0.tar.gz

# Install CLUMPP
RUN wget https://rosenberglab.stanford.edu/software/CLUMPP_Linux64.1.1.2.tar.gz && \
    tar xvfz CLUMPP_Linux64.1.1.2.tar.gz && \
    mv ./CLUMPP_Linux64.1.1.2/CLUMPP /usr/local/bin && \
    chmod +x  /usr/local/bin/CLUMPP && \
    rm -rf ./CLUMPP*

# Make script executable
RUN chmod a+x /usr/local/bin/arrange
RUN chmod a+x /usr/local/bin/BsTpedTmap
RUN chmod a+x /usr/local/bin/ConsensusTree
RUN chmod a+x /usr/local/bin/FixGraphlanXml
RUN chmod a+x /usr/local/bin/MakeBootstrapLists
RUN chmod a+x /usr/local/bin/MakeTree


