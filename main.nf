include {PREPROCESSING} from './workflows/PREPROCESSING.nf'
include {PREDICT3D} from './workflows/PREDICT3D.nf'

workflow {

    // Check if manifest parameter is provided
    if (!params.manifest) {
        log.error("Manifest file is required. Please provide it using --manifest <path_to_manifest>")
        exit 1
    }

    if (!file(params.manifest).exists()) {
        log.error("Manifest file not found at: ${params.manifest}")
        exit 1
    }

    PREPROCESSING(channel.fromPath(params.manifest))

    PREDICT3D(PREPROCESSING.out) // channel of tuples (meta, seq)

}




def parse_mnf(mnf) {
    /*
    -----------------------------------------------------------------
    Parses the manifest file to create a channel of metadata and 
    FASTA files.

    Also, checks if there are empty sample_id duplicated.

    -----------------------------------------------------------------

    - **Input**:
        mnf (path to the manifest file)

    - **Output**: 
        Channel with tuples of metadata and FASTQ file pairs.

    -----------------------------------------------------------------
    */
    // Read manifest file into a list of rows
    def mnf_rows = channel.fromPath(mnf).splitCsv(header: true, sep: ',')

    // Collect sample IDs and validate
    def observed_ids = []
    def errors = 0
    
    def _errors_ch = mnf_rows.map { row ->
        def id = row.id

        // Check if sample_id is empty
        if (!id) {
            log.error("Empty sample_id detected.")
            errors += 1
        } else {
            // Check for unique sample IDs
            if (observed_ids.contains(id)) {
                log.error("${id} is duplicated")
                errors += 1
            } else {
                observed_ids << id
            }
        
            return errors
        }
        }
        // be sure that the number of errors is evaluated after all rows are processed
        .collect() 
        // kill the pipeline if errors are found
        .subscribe{ _v ->
        if (errors > 0) {
            log.error("${errors} critical errors in the manifest were detected.")
            exit 1
        }
    }

    // If validation passed, create the channel
    def mnf_ch = mnf_rows.map { row -> 
                    // set meta
                    def meta = [
                      // id is internal to the pipeline and taxid 
                      // is added to it latter
                      id: row.id,
                      // sample_id is explictily used on the 
                      // publishing of files paths
                      label: row.label
                    ]
                    // set files
                    def fasta_file_path = row.fasta_file_path
                    // declare channel shape
                    tuple(meta, fasta_file_path)
                 }

    return mnf_ch // tuple(meta, [fastq_pairs])
}