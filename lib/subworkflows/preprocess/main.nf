
include {transpose; prune; makeBSlists} from "../../processes/preprocess"

workflow PREPROCESS {
    main:
        if( params.ftype == 'vcf' || params.ftype == 'bcf' ){
            input_ch = Channel.from([
                params.ftype,
                file(params.infile),
                null,
                null,
            ])
        } else if (params.ftype == 'bed'){
            input_ch = Channel.from([
                params.ftype,
                file("${params.infile}.bed"),
                file("${params.infile}.bim"),
                file("${params.infile}.fam"),
            ])
        } else if (params.ftype == 'ped'){
            input_ch = Channel.from([
                params.ftype,
                file("${params.infile}.ped"),
                file("${params.infile}.map"),
                null,
            ])
        } else if (params.ftype == 'tped'){
            input_ch = Channel.from([
                params.ftype,
                file("${params.infile}.tped"),
                file("${params.infile}.tfam"),
                null,
            ])
        } else {
            error "Invalid file type: ${params.ftype}"
        }
        input_ch = input_ch | collect | map{ ftype, in1, in2, in3 -> [ftype, [in1, in2, in3] - null] }
        input_ch | view
        if (params.prune){
            input_ch | prune
            tped = prune.out[0]
            tfam = prune.out[1]
        } else {
            if (params.ftype != "tped"){
                input_ch | transpose
                tped = transpose.out[0]
                tfam = transpose.out[1]
            } else {
                tped = file("${params.infile}.tped", checkIfExists: true)
                tfam = file("${params.infile}.tfam", checkIfExists: true)
            }
        }
        makeBSlists(tped, tfam)
        results = makeBSlists.out

    emit:
        tped
        tfam
        results
}