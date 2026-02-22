process preprocess_manifest {



    input:
        path(manifest_file)
    
    output:
        tuple path("processed_manifest.csv"), path("merged.fasta")
    
    script:
        
        """
        preprocess_manifest.py ${manifest_file} processed_manifest.csv merged.fasta        
        """
}

