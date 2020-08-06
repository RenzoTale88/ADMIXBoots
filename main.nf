#!/usr/bin/env nextflow
 
/*
 * Defines some parameters in order to specify the refence genomes
 * and read pairs by using the command line options
 * if Nsnps is set to 0, use all
 */
params.infile = "file.vcf.gz"
params.ftype = 'bed'
params.spp = 'cow'
params.bootstrap = 10
params.nk = 10
params.outfolder = "${baseDir}/OUTPUT"
params.allowExtrChr = '--allow-extra-chr'
params.setHHmiss = '--set-hh-missing'
params.moreplinkopt = ''
params.variants2use = 1000000
params.pruneP = "50000 1 0.1"


/*
 * Step 1. Prune input data
 */
process prune {
    tag "prune"

    memory { 8.GB * task.attempt }
    time { 6.hour * task.attempt }
    
    output:
    tuple "pruned.bed", "pruned.bim", "pruned.fam" into pruned_ch
    
    script:
    if( params.ftype == 'vcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --make-bed --out pruned --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'bcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --make-bed --out pruned --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'ped' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --make-bed --out pruned --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'bed' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --make-bed --out pruned --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if ( params.ftype == "tped" )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --tfile ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --tfile ${params.infile} --make-bed --out pruned --extract PRUNE.prune.in --threads ${task.cpus}        """
    else
        error "Invalid file type: ${params.ftype}"
}


/*
 * Step 2. Create file TPED/TMAP
 */
process transpose {
    tag "transp"

    memory { 8.GB * task.attempt }
    time { 4.hour * task.attempt }

    input:
    tuple bed, bim, fam from pruned_ch

    output:
    tuple "transposed.tped", "transposed.tfam" into transposed_ch
    file "transposed.tfam" into famfile_ch 

    script:
    """
    plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bed ${bed} --bim ${bim} --fam ${fam} --recode transpose --out transposed ${params.moreplinkopt} --threads ${task.cpus}
    """


}

transposed_ch.into { tr1_ch; tr2_ch }

/*
 * Step 2. Create file lists of bootstrapped markers
 */

process makeBSlists {
    tag "makeBS"

    memory { 8.GB * task.attempt }
    time { 6.hour * task.attempt }

    input:
    tuple tped, tfam from tr1_ch

    output:
    //Save output path to a channel
    path "LISTS" into workdir_ch

    script:
    """
    MakeBootstrapLists ${tped} ${params.bootstrap} ${params.variants2use}
    if [ ! -e LISTS ]; then mkdir LISTS; fi
    mv BS_*.txt ./LISTS
    """
}

process getBSlists {
    tag "getBS"

    memory { 2.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
    //Collect the generated files
    path mypath from workdir_ch
    each k from 2..params.nK
    each x from 1..params.bootstrap

    output:
    // Save every file with it's index in a new channel
    tuple k, x, "${mypath}/BS_${x}.txt" into bootstrapLists

    script:
    """
    echo ${mypath}
    """
}


/*
 * Step 3. Perform parallel IBS tree definition and 
 * concatenate them
 */

process admixboost { 
    tag "boost.${k}.${x}"

    /* Parameters */
    memory { 16.GB * task.attempt }
    time { 12.hour * task.attempt }

    input: 
        tuple k, x, "BS_${x}.txt" from bootstrapLists
        tuple tped, tfam from transposed_ch
 
    output: 
        file "logBS.${k}.${x}.out" into bootstrapsLogs
        tuple k, x, "BS_${x}.${k}.Q", "BS_${x}.${k}.P" into bootstrapResults
  
    script:
    """
    BsTpedTmap ${tped} ${tfam} BS_${x}.txt ${x}
    arrange ${x}
    plink --${params.spp} ${params.allowExtrChr} --threads ${task.cpus} --allow-no-sex --nonfounders --tfile BS_${x} --make-bed --out BS_${x}
    awk 'BEGIN{OFS="\t"};{print "0",\$2,\$3,\$4,\$5,\$6}' BS_${x}.bim > tmp.bim && mv tmp.bim BS_${x}.bim
    admixture --cv -j${task.cpus} BS_${x}.bed ${k} | tee logBS.${k}.${x}.out
    rm BS_${x}.bed BS_${x}.bim BS_${x}.fam BS_${x}.tfam BS_${x}.tped
    """
}

bootstrapResults
    .groupTuple(by: [0])
    .set{ kvals_ch }

process clumpp{
    tag "clumpp.${k}"
    publishDir "${params.outfolder}/CLUMPP", mode: 'copy', overwrite: true

    memory { 32.GB * task.attempt }
    time { 4.hour * task.attempt }

    input:
    tuple k, xs, file(qs), file(ps) from kvals_ch
    file fam from famfile_ch

    output:
    path "./K${k}" into concat_ch
    file "./K${k}/Clumpp_userdef.miscfile" into miscfiles_ch
    file "./K${k}/Sorted.${k}.txt" into sortedfiles_ch
    file "./K${k}/Hpr.${k}.txt" into hprimefiles_ch

    // Concatenate Bootstrap Trees
    script:
    """
    for i in ${qs}; do
        echo \$i
    done > filelist.txt
    AdmixPermute filelist.txt ${fam} ${k} 
    CLUMPP Clumpp_userdef.param
    mkdir K${k}
    mv Clumpp_userdef.* ./K${k}/
    Qscore_sort K${k}/Clumpp_userdef.outfile K${k}/Clumpp_userdef.conv K${k}/Sorted.${k}.txt
    python -c "import sys; KV=sys.argv[2]; HP=[ line.strip().split()[-1] for line in open(sys.argv[1]) if 'highest value of ' in line ]; print('{}\t{}'.format(KV[0], HP[0])) " K${k}/Clumpp_userdef.miscfile ${k} > K${k}/Hpr.${k}.txt
    """
}


process getCVerrors{
    tag "CVerr"
    publishDir "${params.outfolder}/CV", mode: 'copy', overwrite: true

    memory { 4.GB * task.attempt }
    time { 2.hour * task.attempt }

    input:
    file logs from bootstrapsLogs.collect()
    
    output:
    file "Best_K.txt" into cverrs_ch
    file "All_CVs.txt" into allcv_ch

    script:
    """
    for i in ${logs}; do
        grep -w CV \$i >> All_CVs.txt
    done
    BestBootstrappedK All_CVs.txt > Best_K.txt
    """

}


process getHprimes{
    tag "Hpr"
    publishDir "${params.outfolder}/Hpr", mode: 'copy', overwrite: true

    memory { 2.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
    file hfiles from hprimefiles_ch.collect()
    
    output:
    file "Hprimes.txt" into hprimes_ch

    script:
    """
    cat ${hfiles} > Hprimes.txt
    """
}


process makePlots{
    tag "plot"
    publishDir "${params.outfolder}/plots", mode: 'copy', overwrite: true

    memory { 8.GB * task.attempt }
    time { 1.hour * task.attempt }

    input:
    file sortedfiles from sortedfiles_ch.collect()
    file hprimes from hprimes_ch
    file cvs from allcv_ch
    
    output:
    file "*.pdf" into pdfs

    script:
    """
    makePlots ${params.nk}
    """
}