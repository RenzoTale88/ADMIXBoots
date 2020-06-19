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


/*
 * Step 1. Create file TPED/TMAP
 */

process transpose {
    tag "transp"

    errorStrategy { task.exitStatus == 0 ? 'finish' : 'retry' }
    maxRetries = 1
    
    output:
    tuple "transposed.tped", "transposed.tfam" into transposed_ch
    file "transposed.tfam" into famfile_ch 

    script:
    if( params.ftype == 'vcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --recode transpose --out transposed ${params.moreplinkopt} --threads ${task.cpus}
        """
    else if( params.ftype == 'bcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --recode transpose --out transposed ${params.moreplinkopt} --threads ${task.cpus}
        """
    else if( params.ftype == 'ped' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --recode transpose --out transposed ${params.moreplinkopt} --threads ${task.cpus}
        """
    else if( params.ftype == 'bed' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --recode transpose --out transposed ${params.moreplinkopt} --threads ${task.cpus}
        """
    else if ( params.ftype == "tped" )
        """
        ln -s ${params.infile}.tped transposed.tped
        ln -s ${params.infile}.tfam transposed.tfam
        """
    else
        error "Invalid file type: ${params.ftype}"

}

transposed_ch.into { tr1_ch; tr2_ch }

/*
 * Step 2. Create file lists of bootstrapped markers
 */

process makeBSlists {
    tag "makeBS"

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

    input:
    tuple k, xs, file(qs), file(ps) from kvals_ch
    file fam from famfile_ch

    output:
    path "./K${k}" into concat_ch
    file "./K${k}/Clumpp_userdef.miscfile" into miscfiles_ch
    file "./K${k}/Sorted.${k}.txt" into sortedfiles_ch

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
    """
}


process getCVerrors{
    tag "CVerr"
    publishDir "${params.outfolder}/CV", mode: 'copy', overwrite: true

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

    input:
    file miscfiles from miscfiles_ch.collect()
    
    output:
    file "Hprimes.txt" into hprimes_ch

    script:
    """
    for miscfile in ${miscfiles}; do 
        python -c "import sys; KV=[ line.strip().split()[-1] for line in open(sys.argv[1]) if 'K = ' in line ]; HP=[ line.strip().split()[-1] for line in open(sys.argv[1]) if 'highest value of ' in line ]; print('{}\t{}'.format(KV[0], HP[0])) " \$miscfile 
    done > Hprimes.txt
    """
}


process makePlots{
    tag "plot"
    publishDir "${params.outfolder}/plots", mode: 'copy', overwrite: true

    input:
    file sortedfiles from sortedfiles_ch.collect()
    file hprimes from hprimes_ch
    file cvs from allcv_ch
    
    output:
    file "*.pdf" into pdfs

    script:
    """
    makePlots $cvs $hprimes $sortedfiles
    """

}