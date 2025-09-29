#!/usr/bin/env bash
set -euo pipefail

# Base paths
AF3_RESOURCES_DIR=/home/svu/sauyong/af3/
BASE_DIR=${AF3_RESOURCES_DIR}/Bit_1
CODE_DIR=${AF3_RESOURCES_DIR}/code
AF3_IMAGE=/app1/common/singularity-img/hopper/alphafold/alphafold301.sif
WEIGHTS=${AF3_RESOURCES_DIR}/weights
DB=/home/svu/alphafold/data3
DBP=/pscratch/biodata/alphafold/data3
#export AF3_DATABASES_DIR=/home/svu/alphafold/data3
# Either don't use AF3_PARAMETERS or choose either --norun_inference or --norun_data_pipeline
export AF3_PARAMETERS="--norun_inference"
#export AF3_PARAMETERS="--norun_data_pipeline"


# Loop through every subdirectory under Bit_1
for prot_dir in "$BASE_DIR"/*/; do
  # skip non-directories just in case
  [ -d "$prot_dir" ] || continue

  name="$(basename "$prot_dir")"

  json_file="${prot_dir}alphafold_input.json"

  # Check that alphafold_input.json exists before submitting first job

  if [ ! -f "$json_file" ]; then
    echo "Warning: $json_file not found, skipping submission for ${name}"
    continue
  fi

  # First qsub submission (unchanged)
  jobid1=$(qsub <<EOF
#!/bin/bash
#PBS -N af3p_${name}
#PBS -l select=1:ncpus=16:mem=124gb
#PBS -l walltime=08:00:00
#PBS -q auto_free
#PBS -j oe


export AF3_RESOURCES_DIR=${AF3_RESOURCES_DIR}
export AF3_IMAGE=${AF3_IMAGE}
export AF3_CODE_DIR=${CODE_DIR}
export AF3_INPUT_DIR=${prot_dir}
export AF3_OUTPUT_DIR=${prot_dir}
export AF3_MODEL_PARAMETERS_DIR=${WEIGHTS}
export AF3_DATABASES_DIR=${DBP}

singularity exec \\
--bind \$AF3_INPUT_DIR:/root/af_input \\
--bind \$AF3_OUTPUT_DIR:/root/af_output \\
--bind \$AF3_MODEL_PARAMETERS_DIR:/root/models \\
--bind \$AF3_DATABASES_DIR:/root/public_databases \\
\$AF3_IMAGE \\
python \${AF3_CODE_DIR}/alphafold3/run_alphafold.py \\
--json_path=/root/af_input/alphafold_input.json \\
--model_dir=/root/models \\
--db_dir=/root/public_databases \\
--output_dir=/root/af_output \\
--norun_inference
EOF
)

  echo "Submitted first job for ${name}, jobid = $jobid1"
  # --- Extract the "name" value from alphafold_input.json ---
  json_file="${prot_dir}alphafold_input.json"
  
  # Check that file exists first
  if [ -f "$json_file" ]; then
    # Try to extract "name" using jq if available
    if command -v jq >/dev/null 2>&1; then
      extracted_name=$(jq -r '.name // empty' "$json_file")
    else
      # fallback grep + sed: assume line like: "name": "value",
      extracted_name=$(grep -oP '"name"\s*:\s*"\K[^"]+' "$json_file" || echo "")
    fi

    if [ -z "$extracted_name" ]; then
      echo "Warning: 'name' not found in $json_file, skipping second job for ${name}"
      continue
    fi
  else
    echo "Warning: $json_file not found, skipping second job for ${name}"
    continue
  fi

  # Second qsub submission with modified --json_path
  jobid2=$(qsub -W depend=afterok:$jobid1 <<EOF
#!/bin/bash
#PBS -N af3g_${name}
#PBS -l select=1:ncpus=36:ngpus=1:mem=240gb
#PBS -l walltime=04:00:00
#PBS -q auto_free
#PBS -j oe


export AF3_RESOURCES_DIR=${AF3_RESOURCES_DIR}
export AF3_IMAGE=${AF3_IMAGE}
export AF3_CODE_DIR=${CODE_DIR}
export AF3_INPUT_DIR=${prot_dir}/$extracted_name
export AF3_OUTPUT_DIR=${prot_dir}
export AF3_MODEL_PARAMETERS_DIR=${WEIGHTS}
export AF3_DATABASES_DIR=${DB}

singularity exec \\
--nv \\
--bind \$AF3_INPUT_DIR:/root/af_input \\
--bind \$AF3_OUTPUT_DIR:/root/af_output \\
--bind \$AF3_MODEL_PARAMETERS_DIR:/root/models \\
--bind \$AF3_DATABASES_DIR:/root/public_databases \\
\$AF3_IMAGE \\
python \${AF3_CODE_DIR}/alphafold3/run_alphafold.py \\
--json_path=/root/af_input/${extracted_name}_data.json \\
--model_dir=/root/models \\
--db_dir=/root/public_databases \\
--output_dir=/root/af_output \\
--norun_data_pipeline --force_output_dir
EOF
)

  echo "Submitted second job for ${name} with json_path ${extracted_name}_data.json"

done
