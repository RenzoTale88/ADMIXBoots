
include {transpose; prune; makeBSlists} from "../processes/preprocess"

workflow PREPROCESS {
    main:
        if (params.prune){
            prune()
            tped = prune.out[0]
            tfam = prune.out[1]
        } else {
            if (params.ftype != "tped"){
                transpose()
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