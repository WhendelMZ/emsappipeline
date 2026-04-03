include {run_esmfold_api} from '../modules/run_esmfold_api.nf'

workflow PREDICT3D {

    take:
        sequences_ch // channel of tuples (meta, seq)

    main:

    // Run ESMFold API for 3D structure prediction
    run_esmfold_api(sequences_ch)
    run_esmfold_api.out.set{ predicted_structures_ch }

    emit:
        predicted_structures_ch
}