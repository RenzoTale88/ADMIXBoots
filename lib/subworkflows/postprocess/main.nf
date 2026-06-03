
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
        // Run clumpp
        if (params.clumper == "clumppling"){
            grouped_Qs = admixboostres | map{_k, _x, _Q, _P -> [_Q]} | flatten | collect
            clumped = clumppling(grouped_Qs, tfam)

       } else if (params.clumper == "clumppling"){
            grouped_res = admixboostres.groupTuple(by: [0])
            clumped = clumpp(grouped_res, tfam)

            // Collect H'
            getHprimes(clumpp.out[3].collect())

            // Collect all CV errors
            getCVerrors(admixboostlogs.collect() )

            // Run admixEval
            if (!params.skip_full){
                admixfull | evalAdmix | plot_full_admix
                logs = evalAdmix.out.map{it -> it[6]}
                plot_full_stats(logs.collect())
            }

            // Make final plots
            plotAdmixtures(clumpp.out[2])
            plotStats(getHprimes.out, getCVerrors.out[1], getCVerrors.out[2])
        } else {
            error "Invalid clumper specified: ${params.clumper}"
        }
}

