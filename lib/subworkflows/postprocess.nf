
include {clumpp; getCVerrors; getHprimes; plotAdmixtures; plotStats} from "../processes/postprocesses"
include {evalAdmix; plot_evalAdmix} from "../processes/postprocesses"

workflow POSTPROCESS {
    take:
        tped
        tfam
        admixboostlogs
        admixboostres
        admixfull

    main:
        // Run clumpp
        grouped_res = admixboostres.groupTuple(by: [0])
        clumpp(grouped_res, tfam)
        // Collect H'
        getHprimes(clumpp.out[3].collect())

        // Collect all CV errors
        getCVerrors(admixboostlogs.collect() )

        // Make final plots
        //makePlots(clumpp.out[2], getHprimes.out, getCVerrors.out[1])
        plotAdmixtures(clumpp.out[2])
        plotStats(getHprimes.out, getCVerrors.out[1])

        // Run admixEval
        if (!params.skip_full){
            admixfull | evalAdmix | plot_evalAdmix
        }

}

