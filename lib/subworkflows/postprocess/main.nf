
include {clumpp; clumppling; getCVerrors; getHprimes; plotAdmixtures; plotStats} from "../../processes/postprocesses"
include {evalAdmix; plot_full_admix; plot_full_stats} from "../../processes/postprocesses"

workflow POSTPROCESS {
    take:
        tped
        tfam
        admixboostlogs
        admixboostres
        admixfull

    main:
        // Collect all CV errors
        getCVerrors(admixboostlogs.collect())
        // Run clumpp
        if (params.clumper == "clumppling"){
            grouped_Qs = admixboostres | map{_k, _x, _Q, _P -> [_Q]} | flatten | collect
            clumped = clumppling(grouped_Qs, tfam)

            // Collect H'
            hpr_ch = clumped.clumpp_hpr.collect()

       } else if (params.clumper == "clumppling"){
            grouped_res = admixboostres.groupTuple(by: [0])
            clumped = clumpp(grouped_res, tfam)

            // Collect H'
            hpr_ch = getHprimes(clumped.clumpp_hpr.collect())

            // Run admixEval
            if (!params.skip_full){
                admixfull | evalAdmix | plot_full_admix
                logs = evalAdmix.out.map{it -> it[6]}
                plot_full_stats(logs.collect())
            }

            // Make final plots
            plotAdmixtures(clumpp.out[2])
        } else {
            error "Invalid clumper specified: ${params.clumper}"
        }
        plotStats(hpr_ch, getCVerrors.out[1], getCVerrors.out[2])
}

