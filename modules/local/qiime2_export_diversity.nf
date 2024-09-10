process QIIME2_EXPORT_DIVERSITY {
    label 'process_low'

    container "qiime2/core:2023.7"

    input:
    path(qza)

    output:
    path("*.tsv"), emit: tsv

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "QIIME2 does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    // Set filename according to input qza
    if (qza.baseName =~ /_vector/) {
        tname = "alpha-diversity"
    } 
    else if (qza.baseName =~ /_distance_matrix/) {
        tname = "distance-matrix"
    }
    else {
        // Exit with an error if the filename does not match expected patterns
        println qza
        error "Filename doesn't match expected patterns"
    }
    """
    export XDG_CONFIG_HOME="./xdgconfig"
    export MPLCONFIGDIR="./mplconfigdir"
    export NUMBA_CACHE_DIR="./numbacache"

    qiime tools export \\
        --input-path ${qza} \\
        --output-path exported-${qza.baseName}
    cp "exported-${qza.baseName}/${tname}.tsv" "${qza.baseName}.tsv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS
    """
}