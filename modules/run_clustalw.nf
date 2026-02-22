process run_clustalw {

    //x86_64 compatible container
    //container 'biocontainers/clustalw:v2.1lgpl-6-deb_cv1'
    
    //arm64 compatible container
    container 'community.wave.seqera.io/library/clustalw:2.1--890a808de2e3f217'
    
    input:
        path(alignment_input_fasta)
    
    output:
        path("merged.aln")
    
    script:
        
        """
        clustalw2 \
            -align -type=protein \
            -infile=${alignment_input_fasta} \
            -outfile=merged.aln -output=fasta
        """
}