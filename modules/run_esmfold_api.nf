process run_esmfold_api {


    input:
        tuple val(meta), val(seq)

    output:
        tuple val(meta), path("${meta.id}.pdb")

    script:
        // WARNING: Very long sequences (>5–10k aa) may exceed shell limits.
        """
        run_emsfold_esmatlas_api.py \
            --seq ${seq} \
            --out ${meta.id}.pdb \
        """
}