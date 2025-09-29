Running AF3 on Vanda NUS Cluster

This is a guide and repo to get you started on using AF3 on vanda efficiently. From observation, most time consuming part of AF3, we call this the CPU bound part is the first 90% of the entire time used for entire AF3 run. It's best to run these on CPU nodes, on average about 8 minutes for simple runs. Finally run the GPU which for simple searches usually only takes 1-2 minutes.

Currently a apptainer to run AF3 can be found on Vanda cluster

Files and location

Apptainer image /app1/common/singularity-img/hopper/alphafold/alphafold301.sif 
Data3 /home/svu/alphafold/data3 
AF3 Code /home/svu/alphafold/aalphafold3

Request from Google the alphafold3 parameters (the file af3.bin.zst) . Believe this is fingerprinted so do follow terms of condition by Google.

To test


To run batch 
