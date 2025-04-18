


process getBSlists {
    tag "getBS"
    label "small"

    input:
    //Collect the generated files
    path mypath 
    val x 
    val k 

    output:
    // Save every file with it's index in a new channel
    tuple val(k), val(x), path("BS_${x}.txt") 

    script:
    """
    cp ${mypath}/BS_${x}.txt ./
    """
}


process tpedBS {
    tag "tpedBS"
    label "small"

    //Collect the generated files
    input:
    path tped 
    path tfam 
    tuple val(k), path(BS) 

    // Save every file with it's index in a new channel
    output:
    tuple val(k), val("${BS.simpleName}"), path("BS_${BS.simpleName}.tped"), path("BS_${BS.simpleName}.tfam") 

    script:
    """
    BsTpedTmap ${tped} ${tfam} ${BS} ${BS.simpleName}
    arrange ${BS.simpleName}
    """
}


/*
 * Step 3. Perform parallel IBS tree definition and 
 * concatenate them
 */

process admixboost { 
    tag "boost.${k}.${x}"
    label "large"

    input: 
        tuple val(k), val(x), path(tped), path(tfam)
        
    output: 
        path "logBS.${k}.${x}.out"
        tuple val(k), val(x), path("BS_${x}.${k}.Q"), path("BS_${x}.${k}.P")
        
    script:
    def karyo = ""
    if (params.karyo){
        karyo = "--chr-set ${params.karyo}"
    } else if (params.spp) {
        karyo = "--${params.spp}"
    } else {
        karyo = ""
    }
    def extrachr = params.allowExtrChr ? "--allow-extra-chr" : ""
    def sethhmis = params.setHHmiss ? "--set-hh-missing" : ""
    """
    plink ${karyo} ${extrachr} ${sethhmis} --threads ${task.cpus} --allow-no-sex --nonfounders --tfile BS_${x} --make-bed --out BS_${x}
    awk 'BEGIN{OFS="\\t"; n=0; ctg=""}; NR==1{ctg=\$1; print n,\$2,\$3,\$4,\$5,\$6}; NR>1 && \$1==ctg {print n,\$2,\$3,\$4,\$5,\$6}; NR>1 && \$1!=ctg {ctg=\$1; n+=1; print n,\$2,\$3,\$4,\$5,\$6}' BS_${x}.bim > tmp.bim && \\
        mv tmp.bim BS_${x}.bim
    admixture --cv -j${task.cpus} BS_${x}.bed ${k} | \
        tee logBS.${k}.${x}.out && \
        rm BS_${x}.bed BS_${x}.bim BS_${x}.fam BS_${x}.tfam BS_${x}.tped
    """
}

process tped2bed{
    publishDir "${params.outfolder}/pruned", mode: 'copy', overwrite: true
    label 'large'

    input:
    path 'input.tped' 
    path 'input.tfam'

    output:
    tuple path('input.bed'), path('input.bim'), path('input.fam')
    
    script:
    def karyo = ""
    if (params.karyo){
        karyo = "--chr-set ${params.karyo}"
    } else if (params.spp) {
        karyo = "--${params.spp}"
    } else {
        karyo = ""
    }
    def extrachr = params.allowExtrChr ? "--allow-extra-chr" : ""
    def sethhmis = params.setHHmiss ? "--set-hh-missing" : ""
    """
    plink ${karyo} ${extrachr} ${sethhmis} --threads ${task.cpus} --allow-no-sex --nonfounders --tfile input --make-bed --out input
    """
}

process admix {
    publishDir "${params.outfolder}/admixture/k$k/", mode: 'copy', overwrite: true
    label 'large'

    input:
    tuple val(k), path('input.bed'), path('tmp.bim'), path('input.fam')

    output:
    tuple val(k), 
        path('input.bed'), 
        path('input.bim'), 
        path('input.fam'), 
        path("input.${k}.Q"), 
        path("input.${k}.P"), 
        path("logBS.${k}.out")
    
    script:
    """
    awk 'BEGIN{OFS="\\t"; n=0; ctg=""}; NR==1{ctg=\$1; print n,\$2,\$3,\$4,\$5,\$6}; NR>1 && \$1==ctg {print n,\$2,\$3,\$4,\$5,\$6}; NR>1 && \$1!=ctg {ctg=\$1; n+=1; print n,\$2,\$3,\$4,\$5,\$6}' tmp.bim > input.bim
    admixture --cv -j${task.cpus} input.bed ${k} | tee logBS.${k}.out
    """
}