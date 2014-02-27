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
   
   1.4. Change the variables in `CONFIG.<name>.bash`.

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

