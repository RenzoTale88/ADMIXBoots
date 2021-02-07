
include {clumpp; getCVerrors; getHprimes; makePlots} from "../processes/preprocess"

workflow POSTPROCESS {
    take:
        tped
        tfam
        admixboostres
        admixboostlogs

    main:
        // Run clumpp
        grouped_res = admixboostres.groupTuple(by: [0])
        clumpp(grouped_res, fam)
        // Collect H'
        getHprimes(clumpp.out[3])

        // Collect all CV errors
        getCVerrors(admixboostlogs)

        // Make final plots
        makePlots(clumpp.out[3], getHprimes.out, getCVerrors.out)

}

