




/*
 * Step 1. Prune and transpose input data 
 */
process prune {
    label "large"
    tag "prune"

    output:
    path "transposed.tped"  
    path "transposed.tfam" 
    
    script:
    def infile = ""
    if( params.ftype == 'vcf' ){
        infile = "--vcf ${params.infile}"
    } else if( params.ftype == 'bcf' ){
        infile = "--bcf ${params.infile}"
    } else if (params.ftype == 'bed'){

    } else if (params.ftype == 'ped'){

    } else if (params.ftype == 'tped'){

    } else {
        error "Invalid file type: ${params.ftype}"
    }
    """
    plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} ${infile} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
    plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} ${infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
    """
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
    path tped 
    path tfam 

    output:
    path "*.bs.txt"

    script:
    """
    nvar=`python -c "import sys; nrows=sum([1 for line in open(sys.argv[1])]); sys.stdout.write(str(nrows)) if nrows<int(sys.argv[2]) else sys.stdout.write(sys.argv[2])" ${tped} ${params.subset} `
    MakeBootstrapLists ${tped} ${params.bootstrap} \$nvar
    """
}
