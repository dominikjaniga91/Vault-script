#!/bin/bash

source_tab=()

echo "Provide source directory:"
read source_dir
echo "Provide destination directory:"
read dest_dir

function get_function() {

  files=$(vault kv list $1)
  for file in $files
  do
    if [[ "$file" == */ ]];  then
      get_function ${1}$file
    elif [[ "$file" != "Keys" && "$file" != "----" ]]; then
      from_dir="$1$file"
      source_tab=(${source_tab[@]} "${from_dir}")
      to_dir=${from_dir/$source_dir/$dest_dir}
      echo "Moving secrets from $from_dir to $to_dir"
      vault kv get -format=json $from_dir | jq '.data."data"' > vault.json
      vault kv put $to_dir @vault.json
    fi
  done
}


get_function $source_dir

echo "Secrets from destination directory"

dest_tab=()

function get_destination_secrets() {

  files=$(vault kv list $1)
  for file in $files
  do
    if [[ "$file" == */ ]];  then
      get_destination_secrets ${1}$file
    elif [[ "$file" != "Keys" && "$file" != "----" ]]; then
      dest_tab=(${dest_tab[@]} $1$file)
    fi
  done
}

get_destination_secrets $dest_dir

if [[ ${#source_tab[@]} == ${#dest_tab[@]} ]]; then
  echo "Number of secrets is correct ${#source_tab[@]}"
else
  echo "Number of secrets is incorect. Source: ${#source_tab[@]}, destination: ${#dest_tab[@]}"
fi

function compare_json() {
  
  equals=0

  for ((i = 0; i < ${#source_tab[@]}; ++i));
  do
    vault kv get -format=json ${source_tab[i]} | jq '.data."data"' > src.json
    vault kv get -format=json ${dest_tab[i]} | jq '.data."data"' > dst.json
    diff=$(diff <(jq -S . src.json) <(jq -S . dst.json))
    if [[ $diff == "" ]]; then
      equals=$((equals+1))
    else
      echo "Not equals"
      echo "Source: "
      vault kv get -format=json ${source_tab[i]}
      echo "Destination: "
      vault kv get -format=json ${dest_tab[i]}
    fi

  done
  if [[ $equals == ${#source_tab[@]} ]]; then
    echo "All secrets equals"
  fi
} 

compare_json
