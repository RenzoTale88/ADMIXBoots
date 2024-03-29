# ADMIXBoots
## Nextflow Bootstrapped ADMIXTURE workflow

## Introduction
*ADMIXBoots* is a nextflow implementation of a bootstrapped admixture pipeline.

**Update 04/2023**: in addition of running the bootstrapped admixture analysis, the workflow now runs also a post-pruning, full-dataset admixture run, generates the plots and statistics for the full-dataset analyses, and run evalAdmix on the full dataset analyses, providing a more comprehensive picture of the dataset in an highly automated way.

## Dependencies
### Nextflow
Nextflow needs to be installed and in your path to be able to run the pipeline (see [here](https://www.nextflow.io/)). The workflow comes with a docker container as well as an anaconda environment that can be used to run all the dependencies (see below).
We provide few custom configurations for HPC systems, so these might need to be changed and expanded depending on the need.

### Profiles
*ADMIXBoots* comes with a series of pre-defined profiles:
 - standard: this profile runs all dependencies in docker and other basic presets to facilitate the use
 - docker: use docker to run the workflow 
 - singularity: use singularity to run the container
 - local: runs using local exe instead of containerized/conda dependencies (see manual installation for further details)
 - uge: runs using UGE scheduling system
 - sge: runs using SGE scheduling system
A docker image is available with all the dependencies at tale88/nf-roh. This docker ships all necessary dependencies to run nf-roh. 
This is the recommended mode of usage of the software, since all the dependencies come shipped in the container.

### Docker installation
The recommended way to run the workflow, together with `singularity`. To run the workflow using `docker`, first install the desktop application from [here](https://www.docker.com/products/docker-desktop/). The clone the repository and create the docker image as follow:
```
git clone https://github.com/RenzoTale88/ADMIXBoots
cd ADMIXBoots
docker build -t admixboots:latest .
```
If you need the singularity container, simply convert it using:
```
docker save admixboots:latest > admixboots.tar && \
   singularity build admixboots.sif docker-archive://${PWD}/admixboots.tar
```
Then, you can run the workflow using the appropriate profile and pointing to the correct image:
```
nextflow run RenzoTale88/ADMIXBoots [OPTIONS] -profile docker -with-docker admixboots:latest
```
or
```
nextflow run RenzoTale88/ADMIXBoots [OPTIONS] -profile singularity -with-singularity ${PWD}/admixboots.sif
```

### Manual installation
In the case the system doesn't support docker/singularity, it is possible to download them all through the script install.sh.
This script will download a series of software and save them in the ./bin folder, including:
 1. [plink](https://www.cog-genomics.org/plink)
 2. [admixture](https://dalexander.github.io/admixture/download.html)
 3. [clumpp](https://rosenberglab.stanford.edu/clumpp.html)
 4. [python3](https://www.python.org/downloads/), with packages:
    1. numpy
    2. pandas
 5. [R](https://www.r-project.org/) with packages:
    1. ggplot2
    2. tidyverse
    3. reshape2
    4. forcats
    5. ggthemes
    6. patchwork
 6. [evalAdmix](http://www.popgen.dk/software/index.php/EvalAdmix)

Remember to add the ```bin``` folder to your path with the command:
```
export PATH=$PATH:$PWD/bin
```
Or link te folder to the working directory:
```
ln -s /PATH/TO/bin
```

Ready to go!


## Running the pipeline
Note: I am currently working on the test dataset for the analysis.
To test the pipeline locally, simply run:
```
nextflow run RenzoTale88/ADMIXBoots 
    -profile test,docker
```
This will download and run the pipeline on the two toy genomes provided and generate liftover files. If you have all dependencies installed locally you can omit ```docker``` from the profile configuration.
To see all the parameters, you can run the command:
```
nextflow run RenzoTale88/ADMIXBoots --help
```

# References
Test data were published from ADAPTmap and are now [publicly available](https://datadryad.org/stash/dataset/doi:10.5061/dryad.v8g21pt).
Chang CC, Chow CC, Tellier LCAM, Vattikuti S, Purcell SM, Lee JJ (2015) Second-generation PLINK: rising to the challenge of larger and richer datasets. [GigaScience, 4](https://doi.org/10.1186/s13742-015-0047-8).

Alexander DH, Lange K "Enhancements to the ADMIXTURE algorithm for individual ancestry estimation." [BMC Bioinformatics 2011](https://doi.org/10.1186/1471-2105-12-246)

Mattias Jakobsson, Noah A. Rosenberg, CLUMPP: a cluster matching and permutation program for dealing with label switching and multimodality in analysis of population structure, [Bioinformatics, Volume 23, Issue 14, 15 July 2007, Pages 1801–1806](http://bioinformatics.oxfordjournals.org/cgi/content/full/23/14/1801)