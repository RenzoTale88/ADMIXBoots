


process clumpp{
    label "vlarge"
    tag "clumpp.${k}"
    publishDir "${params.outfolder}/CLUMPP", mode: 'copy', overwrite: true

    input:
    tuple val(k), val(xs), path(qs), path(ps) 
    path fam

    output:
    path "./K${k}"
    path "./K${k}/Clumpp_userdef.miscfile" 
    path "./K${k}/Sorted.${k}.txt" 
    path "./K${k}/Hpr.${k}.txt"

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
    label 'medium'
    publishDir "${params.outfolder}/CV", mode: 'copy', overwrite: true

    input:
    path logs
    
    output:
    path "Best_K.txt"
    path "All_CVs.txt"

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
    label 'small'
    publishDir "${params.outfolder}/Hpr", mode: 'copy', overwrite: true

    input:
    path hfiles
    
    output:
    path "Hprimes.txt"

    script:
    """
    cat ${hfiles} > Hprimes.txt
    """
}


process makePlots{
    tag "plot"
    label 'medium'
    publishDir "${params.outfolder}/plots", mode: 'copy', overwrite: true

    input:
    path sortedfiles
    path hprimes
    path cvs
    
    output:
    path "*.pdf" 

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