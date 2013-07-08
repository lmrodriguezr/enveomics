@author: Luis Miguel Rodriguez-R <lmrodriguezr at gmail dot com>

@update: Mar-17-2013

@license: artistic 2.0

@status: semi

@pbs: yes

# IMPORTANT

This pipeline was developed for the [PACE cluster](http://pace.gatech.edu/).  You
are free to use it in other platforms with adequate adjustments.  It is largely
based on Luo _et al._ 2012, ISME J.

# PURPOSE

This pipeline assemblies coupled and/or single reads from one or more libraries.
It assumes that the reads have been quality-checked and trimmed.

# HELP

1. Files preparation:

   1.1. Copy this folder to the cluster.
   
   1.2. Copy the sequences to the cluster.  Only trimmed/filtered reads are used.
      All the files are expected to be in the same folder, and the filenames must
      end in `.CoupledReads.fa` or `.SingleReads.fa`.
   
   1.3. Copy the file `CONFIG.mock.bash` to `CONFIG.<name>.bash`, where `<name>` is a
      short name for your run (avoid characters other than alphanumeric).
   
   1.4. Change the variables in `CONFIG.<name>.bash`.  Notice that this pipeline
      supports running several libraries at the same time, but it's strongly
      recomended to run only one per config file, because the insert length
      (in step 2) and the selected k-mers (in step 3) are fixed for all the
      included libraries.  Also, there is a technical consideration:  The first
      step will execute parallel jobs for each odd number between 21 and 63, and
      SOAP will use 16 CPUs by default, which means 357 CPUs will be requested
      per library in step 2.  It's a bad idea to run many libraries at the same
      time.

   1.5. If you have Mate-paired datasets (for example, prepared with Nextera), first
      reverse-complement all the reads.  See also the `VELVETG_EXTRA` variable in
      the `CONFIG.<name>.bash` file.

2. Velvet and SOAP assembly:
   
   2.1. Execute `./RUNME-2.bash <name>` in the head node (see [troubleshooting](#troubleshooting) #1).
   
   2.2. Monitor the tasks named velvet_* and soap_*.
   
   2.3. Once completed, make sure the files .proc contain only the
      word "done".  To do this, you may execute:
```
      grep -v '^done$' *.proc
```

      If successful, the output of the above command should be empty.  See
      [Troubleshooting](#troubleshooting) #2 and #3 below if one or more of your jobs failed.

3. K-mers selection:
   
   3.1. If you completed step 2, execute `./RUNME-3.bash <name>` in the head
      node.
   
   3.2. Once completed, download and open the files `*.n50.pdf`.
   
   3.3. Select the three "best" k-mers for Velvet and for SOAP (they don't
      have to be the same).  There is no well-tested method to select the
      "best", and this is why this protocol is not automated, but semi-
      automated.  A generally good rule-of-thumb is: pick one that optimizes
      the amount of sequences used (these are the grey bars in the plot;
      usually this is the smallest k-mer), pick one that optimizes the N50
      (this is the dashed red line; usually this is a large k-mer), and pick
      one that optimizes both (something in the middle).  You can select
      more or less than three k-mers, this is just a suggestion.

4. Newbler assembly:
   
   4.1. Edit the file `CONFIG.<name>.bash`: set the variables `K_VELVET` and
      `K_SOAP` to contain the lists of "best" selected k-mers for Velvet and
      SOAP, respectively.
   
   4.2. Execute `./RUNME-4.bash <name>` in the head node.
   
   4.3. Monitor the task newbler_*.  Once finished, your assembly is ready.
      Once completed, make sure the file .newbler.proc contain only the
      word "done".  To do this, you may execute:
```
      grep -v '^done$' *.proc
```
      If successful, the output should be empty.
   
   4.4. The final assembly should be located in the `SCRATCH` path, in a folder
      named `<lib>.newbler/assembly/`.  The file `454AllContigs.fna` contains
      all the assembled contigs, `454LargeContigs.fna` contains the contigs
      with 500bp or more in length, and `454NewblerMetrics.txt` contains some
      relevant statistics.


# Comments

* Some scripts contained in this package are actually symlinks to files in the
  _Scripts_ folder.  Check the existance of these files when copied to
  the cluster.

# Troubleshooting

1. Do I really have to change directory (`cd`) to the pipeline's folder everytime
   I want to execute something?
   
   No.  Not really.  For simplicity, this file tells you to execute, for example,
   `./RUNME-2.bash`.  However, you don't really have to be there, you can execute it
   from any location.  For example, if you saved this pipeline in your home
   directory, you can just execute `~/assembly.pbs/RUNME-2.bash` insted from any
   location in the head node.

2. I executed step 2, and Velvet worked but SOAP failed (or vice versa).  Can I
   submit only one of them?

   Yes.  To execute only Velvet, run:
```
   ./RUNME-2.bash <name> velvet
```

   To execute only SOAP, run:
```
   ./RUNME-2.bash <name> soap
```

3. I ran step 2, and most of the jobs finished, but few of them failed.  Can I
   submit only few K-mers?

   Yes.  To execute one kmer (say, the k-mer 33 of SOAP), run:
```
   ./RUNME-2.bash <name> soap 33
```

   You can also execute more than one kmer, using a comma-separated list.  For
   example, to re-submit the k-mers 37, 39, and 41 of Velvet, run:
```
   ./RUNME-2.bash <name> velvet 37,39,41
```

4. What are the numbers on the job names of step 2?

   The K-mer.  Each k-mer has it's own job, but they are "arrayed", to simplify
   administration: notice that all the jobs of Velvet and all the jobs of SOAP
   share the same job ID.

5. Some jobs are being killed, why?

   5.1. First, check the log file created by the pipeline.  The name is typically
      the output prefix and the .log extension.  For velvet, there are two log files,
      the `.glog` and the `.hlog`.  You may find the problem there.

   5.2. Now, check the error file in your HOME directory.  The name depends on the
      job, the library and the task.  For example: `~/soap_Mg_2-37.e1999838` is the
      error file for step 2, task soap, library Mg_2, k-mer 37.  The appending
      number after the 'e' is the job ID.  If this file contains errors probably
      related to the pipeline, please let me know.

   5.3. If you still have no clues, check the output file in your `HOME` directory.  The
      name is just like the name of the error file (see #5.2 above), but with 'o'
      instead of 'e'.  Compare the lines 'Resources' (what we asked the scheduler for)
      and 'Rsrc Used' (what the job actually used).  A typical problem is that your
      job may need more RAM than we asked for (the value of 'mem' in both lines).  If
      the RAM used is larger than the RAM requested, the scheduler probably killed
      your job.  To solve this, just go to your config file, and set the variable
      RAMMULT to a number larger than 1.  For example, if you want to ask for double the
      RAM, set `RAMMULT=2`.  You can also include simple arithmetic operations, like
      `RAMMULT=3/2`.  If you want to add a fixed ammount of RAM, in Gib, use addition.
      For example, to add 10G, set `RAMMULT=1+10`.

   5.4.  Still no idea?  Try running the job again, sometimes the jobs fail with no
      apparent reason, but they succeed when re-submited.  If your job keeps failing,
      please gather as much information (the log, error and output files should be
      enough) and let me take a look.

6. In the step 2, some k-mers keep failing, and I just want to give up on them, can I?
   
   Yes.  Step 3 will analyze only completed jobs, so you can just ignore these faulty
   k-mers.  Very small k-mers, for example, sometimes need too much memory, and very
   large k-mers in Velvet sometimes need too much time.  If you don't think you're
   missing too much, just ignore them.

