FROM continuumio/miniconda3 AS build

LABEL authors="andrea.talenti@ed.ac.uk" \
      description="Docker image containing base requirements for ADMIXBoots"

# Install the package as normal:
COPY environment.yml .
RUN conda env create -f environment.yml

# Install conda-pack:
RUN conda install -c conda-forge conda-pack

# Use conda-pack to create a standalone enviornment
# in /venv:
RUN conda-pack -n admixboots -o /tmp/env.tar && \
  mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
  rm /tmp/env.tar

# We've put venv in same path it'll be in final image,
# so now fix up paths:
RUN /venv/bin/conda-unpack


# The runtime-stage image; we can use Debian as the
# base image since the Conda env also includes Python
# for us.
FROM debian:buster AS runtime

# Add missing executable from local repo
ADD ./bin/AdmixPermute /usr/local/bin/
ADD ./bin/arrange /usr/local/bin/ 
ADD ./bin/BestBootstrappedK /usr/local/bin/
ADD ./bin/BsTpedTmap /usr/local/bin/
ADD ./bin/MakeBootstrapLists /usr/local/bin/
ADD ./bin/makePlots /usr/local/bin/
ADD ./bin/AdmixturePlot /usr/local/bin/
ADD ./bin/StatsPlots /usr/local/bin/

# Copy /venv from the previous stage:
COPY --from=build /venv /venv

# When image is run, run the code with the environment
# activated:
ENV PATH /venv/bin/:$PATH
SHELL ["/bin/bash", "-c"]
