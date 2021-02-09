def helpMessage() {
  log.info '''
================================================================
           _____  __  __ _______   ______              _       
     /\\   |  __ \\|  \\/  |_   _\\ \\ / /  _ \\            | |      
    /  \\  | |  | | \\  / | | |  \\ V /| |_) | ___   ___ | |_ ___ 
   / /\\ \\ | |  | | |\\/| | | |   > < |  _ < / _ \\ / _ \\| __/ __|
  / ____ \\| |__| | |  | |_| |_ / . \\| |_) | (_) | (_) | |_\\__ \\
 /_/    \\_\\_____/|_|  |_|_____/_/ \\_\\____/ \\___/ \\___/ \\__|___/
                                                                                                                                                         
================================================================
      '''
    log.info"""

    Usage:

    The typical command for running the pipeline is as follows:

      nextflow run RenzoTale88/ADMIXBoots --infile ./data/plink_root_name --ftype bed --out TEST -profile standard

    Mandatory arguments:
      --infile [file]                 Path to input genotypes (root for plink, accepted also vcf and bcf).
      --ftype [ftype]                 Input genotype format. 
                                      Available: bed, ped, tped, vcf, bcf
      --spp [species]                 Plink species name. (Default: cow)
      -profile [str]                  Configuration profile to use. Can use multiple (comma separated)
                                      Available: standard, conda, docker, singularity, eddie, sge, uge

    Alignment arguments:
      --bootstrap [int]               Number of bootstrap to perform. (Default: 10)
      --nk [int]                      Number of cluster to compute, intended as range from 2 to nk. (Default: 10)
      --subset                        Subsample the number of markers to the specified value. (Default: 100000)
                                      If value is larger than the number of markers, it will be automatically reduced to
                                      the number of markers present in the dataset, allowing for repetition of variants.
      --clumpp_greed                  Specifies CLUMPP algorithm greedyness (Default: 3)
                                      Available: 1 or "FullSearch", 2 or "Greedy" and 3 or "LargeKGreedy" 
      --prune                         Prune the samples? (Default: false)
      --prune_params                  Pruning parameters for plink --indep-pairwise (Default: 500 5 0.5)
      --allowExtrChr                  Allow presence of extra chromosomes in plink input file (Default: --allow-extra-chr)
      --setHHmiss                     Set heterozygote haploids as missing (Default: --set-hh-missing)
      --moreplinkopt                  Define additional plink options (Default: "")

    Other
      --outfolder                     Output folder name (Default: 'OUTPUT')
      --publish_dir_mode [str]        Mode for publishing results in the output directory. Available: symlink, rellink, link, copy, copyNoFollow, move (Default: copy)"""
}

