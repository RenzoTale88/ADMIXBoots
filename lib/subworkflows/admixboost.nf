
include {admixboost; getBSlists} from "../processes/admixture.nf"

workflow ADMIXBOOST {
    take:
        tped
        tfam
        lists

    main:
        // Define K and bootstrap values 
        n_boot = Channel
          .from( 1..params.bootstrap )
        n_k = Channel
          .from( 1..params.nk )

        getBSlists(lists, n_boot, n_k)
        admixboost( getBSlists.out, tped, tfam )

    emit:
        admixboost.out[0]
        admixboost.out[1]

}