


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
    """
    plink --${params.spp} ${params.allowExtrChr} --threads ${task.cpus} --allow-no-sex --nonfounders --tfile BS_${x} --make-bed --out BS_${x}
    awk 'BEGIN{OFS="\t"};{print "0",\$2,\$3,\$4,\$5,\$6}' BS_${x}.bim > tmp.bim && mv tmp.bim BS_${x}.bim
    admixture --cv -j${task.cpus} BS_${x}.bed ${k} | tee logBS.${k}.${x}.out
    rm BS_${x}.bed BS_${x}.bim BS_${x}.fam BS_${x}.tfam BS_${x}.tped
    """
}
