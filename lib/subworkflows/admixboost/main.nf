
include {admixboost; getBSlists; tpedBS} from "../../processes/admixture"
include {tped2bed; admix} from "../../processes/admixture"

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
        
        // Run tped bootstrapping
        tpedBS(tped, tfam, n_k)
        admixboost( tpedBS.out )

        // Perform full admixture
        if (params.skip_full){
            full = Channel.empty() 
        } else {
            tped2bed(tped, tfam)
            Channel
                .of( 2..params.nk )
                .combine(tped2bed.out)
                .set{infams}
            infams | admix
            full = admix.out
        }
        

    emit:
        logs = admixboost.out[0]
        qps = admixboost.out[1]
        full = full


}