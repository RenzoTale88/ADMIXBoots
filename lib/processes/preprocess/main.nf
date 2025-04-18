




/*
 * Step 1. Prune and transpose input data 
 */
process prune {
    label "vlarge"
    tag "prune"

    input:
    tuple val(mode),
        path(inputs)

    output:
    path "transposed.tped"  
    path "transposed.tfam" 
    
    script:
    def karyo = ""
    if (params.karyo){
        karyo = "--chr-set ${params.karyo}"
    } else if (params.spp) {
        karyo = "--${params.spp}"
    } else {
        karyo = ""
    }
    def infile = ""
    if( mode == 'vcf' || mode == 'bcf'){
        infile = "--${mode} ${inputs[0]}"
    } else if (mode == 'bed'){
        infile = "--bed ${inputs[0]} --bim ${inputs[1]} --fam ${inputs[2]}"
    } else if (mode == 'ped'){
        infile = "--ped ${inputs[0]} --map ${inputs[1]}"
    } else if (mode == 'tped'){
        infile = "--tped ${inputs[0]} --tfam ${inputs[1]}"
    } else {
        error "Invalid file type: ${params.ftype}"
    }
    def extrachr = params.allowExtrChr ? "--allow-extra-chr" : ""
    def sethhmis = params.setHHmiss ? "--set-hh-missing" : ""
    def half_calls_cfg = "--vcf-half-call ${params.halfcalls}"
    """
    plink ${karyo} ${extrachr} ${sethhmis} ${infile} ${half_calls_cfg} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
    plink ${karyo} ${extrachr} ${sethhmis} ${infile} ${half_calls_cfg} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
    """
}


process transpose {
    label "large"
    tag "transpose"

    input:
    tuple val(mode),
        path(inputs)

    output:
    path "transposed.tped"  
    path "transposed.tfam" 
    
    script:
    def karyo = ""
    if (params.karyo){
        karyo = "--chr-set ${params.karyo}"
    } else if (params.spp) {
        karyo = "--${params.spp}"
    } else {
        karyo = ""
    }
    def infile = ""
    if( mode == 'vcf' || mode == 'bcf'){
        infile = "--${mode} ${inputs[0]}"
    } else if (mode == 'bed'){
        infile = "--bed ${inputs[0]} --bim ${inputs[1]} --fam ${inputs[2]}"
    } else if (mode == 'ped'){
        infile = "--ped ${inputs[0]} --map ${inputs[1]}"
    } else if (mode == 'tped'){
        infile = "--tped ${inputs[0]} --tfam ${inputs[1]}"
    } else {
        error "Invalid file type: ${params.ftype}"
    }
    def extrachr = params.allowExtrChr ? "--allow-extra-chr" : ""
    def sethhmis = params.setHHmiss ? "--set-hh-missing" : ""
    def half_calls_cfg = "--vcf-half-call ${params.halfcalls}"
    if (params.ftype != 'tped')
    """
    plink ${karyo} ${extrachr} ${sethhmis} ${infile} ${half_calls_cfg} --recode transpose --out transposed --threads ${task.cpus}
    """
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
