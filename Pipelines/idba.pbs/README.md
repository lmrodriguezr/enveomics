@author: Luis Miguel Rodriguez-R <lmrodriguezr at gmail dot com>

@update: Feb-26-2015

@license: artistic 2.0

@status: auto

@pbs: yes

# IMPORTANT

This pipeline was developed for the [PACE cluster](http://pace.gatech.edu/).  You
are free to use it in other platforms with adequate adjustments.

# PURPOSE

Performs assembly using IDBA-UD, designed for Single-Cell Genomics and Metagenomics.

# HELP

1. Files preparation:

   1.1. Obtain the enveomics package in the cluster. You can use:
      `git clone https://github.com/lmrodriguezr/enveomics.git`
   
   1.2. Prepare the trimmed reads (e.g., use trim.bs) in interposed FastA format. Files
      must be raw, not zipped or packaged. Filenames must conform the format:
      <name>.CoupledReads.fa, where <name> is the name of the sample. Locate all the
      files within a folder named 04.trimmed_fasta, within your project folder. If you
      used trim.pbs, no further action is necessary.
   
2. Pipeline execution:
   
   2.1. Simply execute `./RUNME.bash <dir> <data_type>`, where `<dir>` is the folder containing
      the 04.trimmed_fasta folder, and `<data_type>` is a supported type of data (see help
      message running `./RUNME.bash` without arguments).

3. What to expect:

   By the end of the run, you should find the folder *05.assembly*, including the following
   files for each dataset:
   
   3.1. `<dataset>`: The IDBA output folder.
   
   3.2. `<dataset>.AllContigs.fna`: All contigs longer than 200bp in FastA format.

   3.2. `<dataset>.LargeContigs.fna`: Contigs longer than 500bp in FastA format.

