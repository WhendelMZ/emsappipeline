include {preprocess_manifest} from '../modules/preprocess_manifest.nf'
include {run_clustalw} from '../modules/run_clustalw.nf'
include {run_mafft} from '../modules/run_mafft.nf'
workflow PREPROCESSING {

    take:
        manifest
    
    main:
        preprocess_manifest(manifest)
        
        // 
        processed_mnf_ch = preprocess_manifest.out.map {it -> it[0] }
        merged_fasta_ch = preprocess_manifest.out.map {it -> it[1] }

        //merged_fasta_ch.splitFasta(record: [id: true, seqString: true]).view()

        // align the manifest and fasta files
        if (params.alignment_tool == 'clustalw') {
            align = run_clustalw(merged_fasta_ch)
        } else if (params.alignment_tool == 'mafft') {
            align = run_mafft(merged_fasta_ch)
        } else {
            log.error("Unsupported alignment tool: ${params.alignment_tool}")
            throw new IllegalArgumentException("Unsupported alignment tool: ${params.alignment_tool}")
        }
        
        //run_clustalw(merged_fasta_ch)
        //run_clustalw.out.view()

        // msa_fasta_ch = align.out.map 
        // align.out.
        //preprocess_In_ch = input_ch.buffer( size: params.buffer_size, remainder: true )

    //preprocess_fasta(preprocess_In_ch)
    //channel.fromPath('data/sample.fa')
    //.splitFasta(record: [id: true, seqString: true])
    //.filter { record -> record.id =~ /^ENST0.*/ }
    //.view { record -> record.seqString }
    
    // pre_processing of protein fasta files
    //PREPROCESSING()

}