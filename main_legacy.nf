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
params.subset = 1000000
params.pruneP = "500 5 0.5"


/*
 * Step 1. Prune and transpose input data 
 */
process prune {
    tag "prune"

    memory { 8.GB * task.attempt }
    time { 6.hour * task.attempt }
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"
    
    output:
    tuple "transposed.tped", "transposed.tfam" into transposed_ch
    file "transposed.tfam" into famfile_ch 
    
    script:
    if( params.ftype == 'vcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --vcf ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'bcf' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bcf ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'ped' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --file ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if( params.ftype == 'bed' )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --bfile ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}
        """
    else if ( params.ftype == "tped" )
        """
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --tfile ${params.infile} --indep-pairwise ${params.pruneP} --out PRUNE ${params.moreplinkopt} --threads ${task.cpus}
        plink --${params.spp} ${params.allowExtrChr} ${params.setHHmiss} --tfile ${params.infile} --recode transpose --out transposed --extract PRUNE.prune.in --threads ${task.cpus}        """
    else
        error "Invalid file type: ${params.ftype}"
}

transposed_ch.into { tr1_ch; tr2_ch }

/*
 * Step 2. Create file lists of bootstrapped markers
 */

process makeBSlists {
    tag "makeBS"

    memory { 8.GB * task.attempt }
    time { 6.hour * task.attempt }
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"

    input:
    tuple tped, tfam from tr1_ch

    output:
    //Save output path to a channel
    path "LISTS" into workdir_ch

    script:
    """
    nvar=`python -c "import sys; nrows=sum([1 for line in open(sys.argv[1])]); sys.stdout.write(str(nrows)) if nrows<int(sys.argv[2]) else sys.stdout.write(sys.argv[2])" ${tped} ${params.subset} `
    MakeBootstrapLists ${tped} ${params.bootstrap} \$nvar
    if [ ! -e LISTS ]; then mkdir LISTS; fi
    mv *.bs.txt ./LISTS
    """
}

process getBSlists {
    tag "getBS"

    memory { 2.GB * task.attempt }
    time { 1.hour * task.attempt }
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"

    input:
    //Collect the generated files
    path mypath from workdir_ch
    each k from 2..params.nK
    each x from 1..params.bootstrap

    output:
    // Save every file with it's index in a new channel
    tuple k, x, "${mypath}/${x}.bs.txt" into bootstrapLists

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
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"

    input: 
        tuple k, x, "${x}.bs.txt" from bootstrapLists
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
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"

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
    python -c "import sys; KV=sys.argv[2]; HP=[ line.strip().split()[-1] for line in open(sys.argv[1]) if 'highest value of ' in line ]; print('{}\t{}'.format(KV, HP[0])) " K${k}/Clumpp_userdef.miscfile ${k} > K${k}/Hpr.${k}.txt
    """
}


process getCVerrors{
    tag "CVerr"
    publishDir "${params.outfolder}/CV", mode: 'copy', overwrite: true

    memory { 4.GB * task.attempt }
    time { 2.hour * task.attempt }
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"

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
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"

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
    clusterOptions "-P roslin_ctlgh -l h_vmem=${task.memory.toString().replaceAll(/[\sB]/,'')}"

    input:
    file sortedfiles from sortedfiles_ch.collect()
    file hprimes from hprimes_ch
    file cvs from allcv_ch
    
    output:
    file "*.pdf" into pdfs

    script:
    $/
    #!/usr/bin/env Rscript
    # Admix plot
    options(stringsAsFactors = F, warn=-1, message = FALSE, readr.num_columns = 0)
    args = commandArgs(T)
    suppressPackageStartupMessages(library(ggplot2, quietly = TRUE))
    suppressPackageStartupMessages(library(tidyverse, quietly = TRUE))
    suppressPackageStartupMessages(library(reshape2, quietly = TRUE))
    suppressPackageStartupMessages(library(forcats, quietly = TRUE))
    suppressPackageStartupMessages(library(ggthemes, quietly = TRUE))
    suppressPackageStartupMessages(library(patchwork, quietly = TRUE))

    # Plot CV errors
    CV = read.table("${cvs}", h=F, sep = ' ') %>% 
        select(K = V3, CV = V4)
    CV[,'K'] = parse_number(CV[,'K'])
    CV[,'K'] = factor(CV[,'K'], levels = sort(unique(CV[,'K'])))

    cvp = CV %>% 
        ggplot(aes(x = K, y=CV)) +
        geom_boxplot() + 
        labs(title = "CV error - 100 bootstrap", x = "K", y = "CV error distribution")
    ggsave("CV_errors.pdf", plot = cvp, device = "pdf", width = 12, height = 8)

    # Plot H prime values
    hpr = read.table("${hprimes}", h=F) %>% 
        select(K = V1, H = V2)
    hpr[,'K'] = factor(hpr[,'K'], levels = sort(unique(hpr[,'K'])))

    hp = hpr %>% 
        ggplot(aes(x = K, y=H)) +
        geom_point() + 
        labs(title = "H' - 100 bootstrap", x = "K", y = "H'")
    ggsave("Hprimes.pdf", plot = hp, device = "pdf", width = 12, height = 8)


    for (k in c(2:${params.nk})){
        fname = paste("Sorted.",k,'.txt', sep = '')
        plotname = paste('ADMIXTURE_PLOT_',k,'.pdf', sep = '')
        toplot = read.table(fname, h = F)
        toplot[,'V1'] = NULL
        colnames(toplot)[1] = 'POP'
        colnames(toplot)[2] = 'IND'
        toplot[,'POP'] = factor(toplot[,'POP'], levels = unique(sort(toplot[,'POP'])))
        toplot = toplot[order(toplot\$POP),]
        cols<-c("red","lightgreen","darkblue","127","hotpink3","orange","lightblue","#C12869","lightcoral","seagreen","#CCFB5D","#E9CFEC","#C3FDB8","#9E8335","#E8A317","purple","yellowgreen","darkgreen","lightgrey","#7F5217","#5819B3","#5CAFA9","#944B21","#FBB917","#6A287E","#7D0552","#C38EC7","#C9C299","blue","#6C4403","#738017","#43C6DB","#EDE275","darkgray","#C34A2C","black","pink","#736AFF","#B93B8F")
        toplot2 = toplot
        colnames(toplot2)[3:ncol(toplot2)] = seq(1:k)
        toplot2 = melt(toplot2, id.vars = c("POP","IND"), variable.name = "K")
        
        kplot <-
            ggplot(toplot2, aes(factor(IND), value, fill = factor(K))) +
            geom_col(color = "gray", size = 0.1) +
            facet_grid(~fct_inorder(POP), switch = "x", scales = "free", space = "free", ) +
            theme_minimal() + labs(x = "", title = paste("K", k, sep = "="), y = "Ancestry", size = 20) +
            scale_y_continuous(expand = c(0, 0)) +
            scale_x_discrete(expand = expand_scale(add = 1)) +
            theme(
            strip.text.x = element_text(angle=75),
            panel.spacing.x = unit(0.00001, "lines"),
            axis.text.x = element_blank(),
            panel.grid = element_blank()
            ) +
            scale_fill_gdocs(guide = FALSE) 
        ggsave(plotname, plot = kplot, height = 7, width = 18, device = "pdf")
    }

    /$
}