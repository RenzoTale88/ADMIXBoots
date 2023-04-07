
include {admixboost; getBSlists; tpedBS} from "../processes/admixture.nf"

workflow ADMIXBOOST {
    take:
        tped
        tfam
        lists

    main:
        // Define K and bootstrap values 
        // n_boot = Channel
        //   .from( 1..params.bootstrap )
        n_k = Channel
          .from( 2..params.nk )
          .combine( lists.flatten() )
        
        // getBSlists(lists, n_boot, n_k)
        // tpedBS(tped, tfam, getBSlists.out)
        tpedBS(tped, tfam, n_k)
        admixboost( tpedBS.out )

    emit:
        admixboost.out[0]
        admixboost.out[1]

}