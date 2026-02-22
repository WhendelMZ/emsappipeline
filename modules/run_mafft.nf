process run_mafft {

    //arm64 compatible container
    //container 'community.wave.seqera.io/library/mafft:7.525--29cc8607eaaa2cc3'
    
    input:
        path(alignment_input_fasta)
    
    output:
        path("merged.aln")
    
    script:
        
        """
        mafft --auto ${alignment_input_fasta} > merged.aln
        """
}