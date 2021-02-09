#!/usr/bin/env nextflow
 nextflow.enable.dsl=2

/*
 * Defines some parameters in order to specify the refence genomes
 * and read pairs by using the command line options
 * if Nsnps is set to 0, use all
 */

// Show help message
if (params.help) {
    include {helpMessage} from './modules/processes/help.nf'
    helpMessage()
    exit 0
}


// Print run informations
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
log.info """\
Nextflow ADMIXBoots v 2.0
=========================================
input name          : $params.infile
file type           : $params.ftype
species             : $params.spp
boostrap N          : $params.bootstrap
N of clusters (k)   : $params.nk
Subset size (n SNPs): $params.subset
CLUMPP greed level  : $params.clumpp_greed
output folder       : $params.outfolder
Prune               : $params.prune
Pruning parameters  : $params.prune_params
Allow extra chr     : $params.allowExtrChr
Set HH missing      : $params.setHHmiss
Additional plink opt: $params.moreplinkopt

""" 

// Include all workflows
include {PREPROCESS} from './lib/subworkflows/preprocess' params(params)
include {ADMIXBOOST} from './lib/subworkflows/admixboost' params(params)
include {POSTPROCESS} from './lib/subworkflows/postprocess' params(params)

workflow {
    main:
        PREPROCESS()
        ADMIXBOOST( PREPROCESS.out[0], PREPROCESS.out[1], PREPROCESS.out[2] )
        POSTPROCESS( PREPROCESS.out[0], PREPROCESS.out[1], ADMIXBOOST.out[0], ADMIXBOOST.out[1] )
}
