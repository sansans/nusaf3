# Running AF3 on Vanda NUS Cluster

This is a guide and repo to get you started on using AF3 on vanda efficiently. From observation, most time consuming part of AF3, we call this the CPU bound part is the first 90% of the entire time used for entire AF3 run. It's best to run these on CPU nodes, on average about 15 minutes for simple run. GPU portion for simple searches usually only takes 2 minutes. Request for 1 GPU in your job as it fits and does not run faster with more GPUs.

Currently an apptainer container used to run AF3 can be found on Vanda cluster

To use, for example from your Vanda home directory,

git clone https://github.com/sansans/nusaf3.git af3 

cd af3

mkdir code 

cp -r /home/svu/alphafold/alphafold3 code

## Files and location

Apptainer image 
>/app1/common/singularity-img/hopper/alphafold/alphafold301.sif 

Data3 
>/home/svu/alphafold/data3 

AF3 Code 
>/home/svu/alphafold/alphafold3

Request from Google the alphafold3 parameters (the file af3.bin.zst) . Believe this is fingerprinted so do follow terms of condition by Google. From Alphafold3  github - [parameter request form](https://forms.gle/svvpY4u2jsHEwWYS6).

## To test interactively

To test, request for a single GPU interactive session. 

Listed below from `run2PV7.txt` , modify the exports accordingly

`export AF3_RESOURCES_DIR=/home/svu/userhome/af3` change to your own home

`export AF3_CODE_DIR=${AF3_RESOURCES_DIR}/code`

`export AF3_INPUT_DIR=${AF3_RESOURCES_DIR}/examples/fold_2PV7` input directory

`export AF3_OUTPUT_DIR=${AF3_RESOURCES_DIR}/examples/fold_2PV7` output directory

Prepare the input directory to have your , in this example `alphafold_input_json` is the input JSON. 

`{
  "name": "2PV7",
  "sequences": [
    {
      "protein": {
        "id": ["A", "B"],
        "sequence": "GMRESYANENQFGFKTINSDIHKIVIVGGYGKLGGLFARYLRASGYPISILDREDWAVAESILANADVVIVSVPINLTLETIERLKPYLTENMLLADLTSVKREPLAKMLEVHTGAVLGLHPMFGADIASMAKQVVVRCDGRFPERYEWLLEQIQIWGAKIYQTNATEHDHNMTYIQALRHFSTFANGLHLSKQPINLANLLALSSPIYRLELAMIGRLFAQDAELYADIIMDKSENLAVIETLKQTYDEALTFFENNDRQGFIDAFHKVRDWFGDYSEQFLKESRQLLQQANDLKQG"
      }
    }
  ],
  "modelSeeds": [1],
  "dialect": "alphafold3",
  "version": 1
}`


```
#!/bin/bash

#PBS -N xaf3test
#PBS -l select=1:ncpus=36:ngpus=1:mem=240gb
#PBS -l walltime=04:00:00
#PBS -q auto_free
#PBS -j oe

cd $PBS_O_WORKDIR/af3


export AF3_RESOURCES_DIR=/home/svu/userhome/af3

export AF3_IMAGE=/app1/common/singularity-img/hopper/alphafold/alphafold301.sif
export AF3_CODE_DIR=${AF3_RESOURCES_DIR}/code
export AF3_INPUT_DIR=${AF3_RESOURCES_DIR}/examples/fold_2PV7
export AF3_OUTPUT_DIR=${AF3_RESOURCES_DIR}/examples/fold_2PV7
export AF3_MODEL_PARAMETERS_DIR=${AF3_RESOURCES_DIR}/weights
export AF3_DATABASES_DIR=/home/svu/alphafold/data3

singularity exec \
     --nv \
     --bind $AF3_INPUT_DIR:/root/af_input \
     --bind $AF3_OUTPUT_DIR:/root/af_output \
     --bind $AF3_MODEL_PARAMETERS_DIR:/root/models \
     --bind $AF3_DATABASES_DIR:/root/public_databases \
     $AF3_IMAGE \
     python ${AF3_CODE_DIR}/alphafold3/run_alphafold.py \
     --json_path=/root/af_input/alphafold_input.json \
     --model_dir=/root/models \
     --db_dir=/root/public_databases \
     --output_dir=/root/af_output
```

## To run batch 

Alphafold3 allows for to split the 2 major internal process, **data pipline** (CPU only) and **inference** (GPU) . To make efficient use of GPU in batch jobs, split the CPU to CPU nodes, the earlier interactive example sample time shown below about GPU is idle 87% of the run. 

Running data pipeline for chain A took 978.14 seconds

Running model inference with seed 1 took 127.40 seconds.

Example is `splitrun.sh` is used to split jobs in a folder with CPU `--norun_inference` and GPU `--norun_data_pipeline` . Sturture your folder, following the example Bit_1, with subfolders, each with it's own `alphafold_input_json` . Change `BASE_DIR=${AF3_RESOURCES_DIR}/Bit_1` in the example.

The split uses an alternative common storage for disk intensive searching. This may not be permenant and maybe subject to change. 




