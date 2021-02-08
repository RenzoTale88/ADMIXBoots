


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
    if [ ! -e K${k} ]; then mkdir K${k}; fi
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
    """
    makePlots ${cvs} ${hprimes} "Sorted"
    """
}