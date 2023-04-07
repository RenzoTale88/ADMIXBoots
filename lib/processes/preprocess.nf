




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
    def karyo = ""
    if (params.karyo){
        karyo = "--chr-set ${params.karyo}"
    } else if (params.spp) {
        karyo = "--${params.spp}"
    } else {
        karyo = ""
    }
    def infile = ""
    if( params.ftype == 'vcf' ){
        def vcf = file(params.infile, checkIfExists: true)
        infile = "--vcf ${vcf}"
    } else if( params.ftype == 'bcf' ){
        def bcf = file(params.infile, checkIfExists: true)
        infile = "--bcf ${bcf}"
    } else if (params.ftype == 'bed'){
        def bed = file("${params.infile}.bed", checkIfExists: true)
        def bim = file("${params.infile}.bim", checkIfExists: true)
        def fam = file("${params.infile}.fam", checkIfExists: true)
        infile = "--bed ${bed} --bim ${bim} --fam ${fam}"
    } else if (params.ftype == 'ped'){
        def ped = file("${params.infile}.ped", checkIfExists: true)
        def map = file("${params.infile}.map", checkIfExists: true)
        infile = "--ped ${ped} --map ${map}"
    } else if (params.ftype == 'tped'){
        def tped = file("${params.infile}.tped", checkIfExists: true)
        def tfap = file("${params.infile}.tfap", checkIfExists: true)
        infile = "--tped ${tped} --tfam ${tfam}"
    } else {
        error "Invalid file type: ${params.ftype}"
    }
    def extrachr = params.allowExtrChr ? "--allow-extra-chr" : ""
    def sethhmis = params.setHHmiss ? "--set-hh-missing" : ""
    """
    plink ${karyo} ${extrachr} ${sethhmis} ${infile} --indep-pairwise ${params.prune_params} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
    plink ${karyo} ${extrachr} ${sethhmis} ${infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
    """
}


process transpose {
    label "large"
    tag "transpose"

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
    if( params.ftype == 'vcf' ){
        def vcf = file(params.infile, checkIfExists: true)
        infile = "--vcf ${vcf}"
    } else if( params.ftype == 'bcf' ){
        def bcf = file(params.infile, checkIfExists: true)
        infile = "--bcf ${bcf}"
    } else if (params.ftype == 'bed'){
        def bed = file("${params.infile}.bed", checkIfExists: true)
        def bim = file("${params.infile}.bim", checkIfExists: true)
        def fam = file("${params.infile}.fam", checkIfExists: true)
        infile = "--bed ${bed} --bim ${bim} --fam ${fam}"
    } else if (params.ftype == 'ped'){
        def ped = file("${params.infile}.ped", checkIfExists: true)
        def map = file("${params.infile}.map", checkIfExists: true)
        infile = "--ped ${ped} --map ${map}"
    } else {
        error "Invalid file type: ${params.ftype}"
    }
    def extrachr = params.allowExtrChr ? "--allow-extra-chr" : ""
    def sethhmis = params.setHHmiss ? "--set-hh-missing" : ""
    if (params.ftype != 'tped')
    """
    plink ${karyo} ${extrachr} ${sethhmis} ${infile} --recode transpose --out transposed --threads ${task.cpus}
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
