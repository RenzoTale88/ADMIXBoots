# ADMIXBoots
## Nextflow Bootstrapped ADMIXTURE workflow

## Introduction
*ADMIXBoots* is a nextflow implementation of a bootstrapped admixture pipeline. 

## Dependencies
### Nextflow
Nextflow needs to be installed and in your path to be able to run the pipeline. 
To do so, follow the instructions [here](https://www.nextflow.io/)

### Profiles
*ADMIXBoots* comes with a series of pre-defined profiles:
 - standard: this profile runs all dependencies in docker and other basic presets to facilitate the use
 - local: runs using local exe instead of containerized/conda dependencies (see manual installation for further details)
 - docker: force the use of docker 
 - singularity: runs the dependencies within singularity
 - conda: runs the dependencies within conda
 - uge: runs using UGE scheduling system
 - sge: runs using SGE scheduling system
A docker image is available with all the dependencies at tale88/nf-roh. This docker ships all necessary dependencies to run nf-roh. 
This is the recommended mode of usage of the software, since all the dependencies come shipped in the container.

### Manual installation
In the case the system doesn't support docker/singularity, it is possible to download them all through the script install.sh.
This script will download a series of software and save them in the ./bin folder, including:
 1. [admixture](https://dalexander.github.io/admixture/download.html)
 2. [plink](https://www.cog-genomics.org/plink) with packages:
    1. numpy
    2. pandas
 3. [python3](https://www.python.org/downloads/)
 4. [clumpp](https://rosenberglab.stanford.edu/clumpp.html)
 5. [R](https://www.r-project.org/) with packages:
    1. ggplot2
    2. tidyverse
    3. reshape2
    4. forcats
    5. ggthemes
    6. patchwork

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
This will download and run the pipeline on the two toy genomes provided and generate liftover files. If you have all dependencies installed locally
you can omit ```docker``` from the profile configuration.

# References

