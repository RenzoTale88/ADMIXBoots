
include {admixboost; getBSlists} from "../processes/admixture.nf"

workflow ADMIXBOOST {
    take:
        tped
        tfam
        lists

    main:
        getBSlists(lists)
        admixboost( getBSlists.out, tped, tfam )

    emit:
        admixboost.out[0]
        admixboost.out[1]

}