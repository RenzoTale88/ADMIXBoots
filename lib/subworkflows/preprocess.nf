
include {transpose; prune; makeBSlists} from "../processes/preprocess"

workflow PREPROCESS {
    main:
        if (params.prune){
            prune()
            tped = prune.out[0]
            tfam = prune.out[1]
        } else {
            transpose()
            tped = transpose.out[0]
            tfam = transpose.out[1]
        }
        makeBSlists(tped, tfam)
        results = makeBSlists.out

    emit:
        tped
        tfam
        results
}