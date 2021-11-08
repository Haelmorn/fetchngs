// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SRA_FASTQ_FTP {
    tag "$meta.id"
    label 'process_medium'
    label 'error_retry'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['run_accession']) }

    conda (params.enable_conda ? "conda-forge::sed=4.7" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://containers.biocontainers.pro/s3/SingImgsRepo/biocontainers/v1.2.0_cv1/biocontainers_v1.2.0_cv1.img"
    } else {
        container "biocontainers/biocontainers:v1.2.0_cv1"
    }

    input:
    tuple val(meta), val(fastq)

    output:
    tuple val(meta), path("*fastq.gz"), emit: fastq
    tuple val(meta), path("*md5")     , emit: md5

    script:
    if (meta.single_end) {
        """
        bash -c 'until curl $options.args -L https://${fastq[0]} -o ${meta.run_accession}.fastq.gz; do sleep 1; done';

        echo "${meta.md5_1} ${meta.run_accession}.fastq.gz" > ${meta.run_accession}.fastq.gz.md5
        md5sum -c ${meta.run_accession}.fastq.gz.md5
        """
    } else {
        """
        bash -c 'until curl $options.args -L https://${fastq[0]} -o ${meta.run_accession}_1.fastq.gz; do sleep 1; done';

        echo "${meta.md5_1} ${meta.run_accession}_1.fastq.gz" > ${meta.run_accession}_1.fastq.gz.md5
        md5sum -c ${meta.run_accession}_1.fastq.gz.md5

        bash -c 'until curl $options.args -L https://${fastq[1]} -o ${meta.run_accession}_2.fastq.gz; do sleep 1; done';

        echo "${meta.md5_2} ${meta.run_accession}_2.fastq.gz" > ${meta.run_accession}_2.fastq.gz.md5
        md5sum -c ${meta.run_accession}_2.fastq.gz.md5
        """
    }
}
