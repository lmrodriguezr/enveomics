@author: Luis Miguel Rodriguez-R <lmrodriguezr at gmail dot com>

@update: Oct-30-2014

@license: artistic 2.0

@status: auto

@pbs: yes

# IMPORTANT

This pipeline was developed for the [PACE cluster](http://pace.gatech.edu/).  You
are free to use it in other platforms with adequate adjustments.

# PURPOSE

Performs various trimming and quality-control analyses over raw reads.

# HELP

1. Files preparation:

   1.1. Obtain the enveomics package in the cluster. You can use:
      `git clone https://github.com/lmrodriguezr/enveomics.git`
   
   1.2. Prepare the raw reads in FastQ format. Files must be raw, not zipped or packaged.
      Filenames must conform the format: <name>.<sis>.fastq, where <name> is the name
      of the sample, and <sis> is 1 or 2 indicating which sister read the file contains.
      Use only '1' as <sis> if you have single reads.
   
   1.3. Gather all the FastQ files into the same folder.

2. Pipeline execution:
   
   2.1. Simply execute `./RUNME.bash <dir>`, where <dir> is the folder containing
      the FastQ files.

3. What to expect:

   By the end of the run, you should find the following folders:
   
   3.1. *01.raw_reads*: Gzip'ed raw FastQ files.
   
   3.2. *02.trimmed_reads*: Trimmed and clipped reads. For each sample, there should be
      nine files for paired-end, and two for single-reads.

   3.3. *03.read_quality*: Quality reports. For each sample, there should be two directories,
      one with SolexaQA++ information, another with FastQC information.

   3.4. *04.trimmed_fasta*: Trimmed and clipped in FastA format (and gzip'ed, in the case of
      individual files for paired-end).


