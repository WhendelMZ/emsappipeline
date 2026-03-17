include {preprocess_manifest} from '../modules/preprocess_manifest.nf'
include {run_clustalw} from '../modules/run_clustalw.nf'
include {run_mafft} from '../modules/run_mafft.nf'
workflow PREPROCESSING {

    take:
        manifest

    main:
        preprocess_manifest(manifest) //

        //
        processed_mnf_ch = preprocess_manifest.out.map {it -> it[0] } // meta
        merged_fasta_ch = preprocess_manifest.out.map {it -> it[1] } // merged fasta

        // TODO: add whendel preprocessing steps

        // align the manifest and fasta files
        if (params.alignment_tool == 'clustalw') {
            run_clustalw(merged_fasta_ch)
            align_out_ch = run_clustalw.out
        } else if (params.alignment_tool == 'mafft') {
            run_mafft(merged_fasta_ch)
            align_out_ch = run_mafft.out
        } else {
            log.error("Unsupported alignment tool: ${params.alignment_tool}")
            throw new IllegalArgumentException("Unsupported alignment tool: ${params.alignment_tool}")
        }

        processed_mnf_ch
            .splitCsv(header: true, sep: ',')
            .map { row -> tuple(row.id, row) }
            .set { mnf_split_ch }


        align_out_ch
            .splitFasta(record: [id: true, seqString: true])
            .map { record -> tuple(record.id, record.seqString) }
            .join(mnf_split_ch) // id, seq, meta
            .map {_id, seq, meta -> tuple(meta, seq) }
            .set { final_output_ch }

    emit:
        final_output_ch
}