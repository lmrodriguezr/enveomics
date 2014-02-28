@author: Luis Miguel Rodriguez-R <lmrodriguezr at gmail dot com>

@update: Feb-20-2014

@license: artistic 2.0

@status: auto

@pbs: yes

# IMPORTANT

This pipeline was developed for the [PACE cluster](http://pace.gatech.edu/).  You
are free to use it in other platforms with adequate adjustments.

# PURPOSE

Simplifies submitting and tracking large BLAST jobs in cluster.

# HELP

1. Files preparation:

   1.1. Obtain the enveomics package in the cluster. You can use: `git clone https://github.com/lmrodriguezr/enveomics.git`
   
   1.2. Prepare the query sequences and the database.
   
   1.3. Copy the file `CONFIG.mock.bash` to `CONFIG.<name>.bash`, where `<name>` is a
      short name for your project (avoid characters other than alphanumeric).
   
   1.4. Change the variables in `CONFIG.<name>.bash`. The **Queue and resources** and the
      **Pipeline** variables are very standard, and can be kept unchanged. The **Paths**
      variables indicate where your input files are and where the output files are to
      be created, so check them carefully. Finally, the **FUNCTIONS** define the core
      functionality of the pipeline, and should also be reviewed. By default, the
      Pipeline simply runs BLAST+, with default parameters and tabular output with two
      extra columns (qlen and slen). However, additional functionality can easily be
      incorporated via these functions, such as BLAST filtering, concatenation, sorting,
      or even execution of other programs instead of BLAST, such as BLAT, etc. Note that
      the output MUST be BLAST-like tabular, because this is the only format supported
      to check completeness and recover incomplete runs.
   
2. Pipeline execution:
   
   2.1. To initialize a run, execute: `./RUNME.bash <name> run`.

   2.2. To check the status of a job, execute: `./RUNME.bash <name> check`.

   2.3. To pause a run, execute: `./RUNME.bash <name> pause` (see 2.1 to resume).

   2.4. To check if your CONFIG defines all required parameters, execute: `./RUNME.bash <name> dry`.

   2.5. To review all the e/o files in the run, execute: `./RUNME.bash <name> eo`.

3. Finalizing:
   
   3.1. `./RUNME.bash <name> check` will inform you if a project finished. If it finished successfully,
      you can review your (split) results in $SCRATCH/results. If you concatenated the results in the
      `END` function, you should have a file with all the results in $SCRATCH/<name>.blast.

   3.2. Usually, checking the e/o files at the end is a good idea (`./RUNME.bash <name> eo`). However,
      bear in mind that this Pipeline can overcome several errors and is robust to most failures, so
      don't be alarmed at the first sight of errors.

# Comments

* Some scripts contained in this package are actually symlinks to files in the
  _Scripts_ folder.  Check the existance of these files when copied to
  the cluster.

# Troubleshooting

1. Do I really have to change directory (`cd`) to the pipeline's folder everytime
   I want to execute something?
   
   No.  Not really.  For simplicity, this file tells you to execute `./RUNME.bash`.
   However, you don't really have to be there, you can execute it
   from any location.  For example, if you saved enveomics in your home
   directory, you can just execute `~/enveomics/blast.pbs/RUNME.bash` insted from any
   location in the head node.

