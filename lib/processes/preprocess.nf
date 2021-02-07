




/*
 * Step 1. Prune and transpose input data 
 */
process prune {
    label "large"
    tag "prune"

    output:
    tuple path("transposed.tped"), path("transposed.tfam")  
    path "transposed.tfam" 
    
    script:
    if( params.ftype == 'vcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'bcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'ped' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'bed' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if ( params.ftype == "tped" )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --tfile ${params.infile} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --tfile ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}        """
    else
        error "Invalid file type: ${params.ftype}"
}


process transpose {
    label "large"
    tag "transpose"

    output:
    path "transposed.tped"  
    path "transposed.tfam" 
    
    script:
    if( params.ftype == 'vcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --recode transpose --out transposed --threads ${task.cpus}
        """
    else if( params.ftype == 'bcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --recode transpose --out transposed --threads ${task.cpus}
        """
    else if( params.ftype == 'ped' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --recode transpose --out transposed --threads ${task.cpus}
        """
    else if( params.ftype == 'bed' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --recode transpose --out transposed --threads ${task.cpus}
        """
    else if ( params.ftype == "tped" )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --tfile ${params.infile} --recode transpose --out transposed --threads ${task.cpus}        """
    else
        error "Invalid file type: ${params.ftype}"
}



/*
 * Step 2. Create file lists of bootstrapped markers
 */

process makeBSlists {
    tag "makeBS"
    label "medium"

    input:
    path(tped)
    path(tfam) 

    output:
    //Save output path to a channel
    path "./LISTS"

    script:
    """
    nvar=`python -c "import sys; nrows=sum([1 for line in open(sys.argv[1])]); sys.stdout.write(str(nrows)) if nrows<int(sys.argv[2]) else sys.stdout.write(sys.argv[2])" ${tped} ${params.subset} `
    MakeBootstrapLists ${tped} ${params.bootstrap} \$nvar
    if [ ! -e LISTS ]; then mkdir LISTS; fi
    mv BS_*.txt ./LISTS
    """
}
