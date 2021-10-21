#!/bin/bash


echo "Provide source directory:"
read source_dir
echo "Provide destination directory:"
read dest_dir

tests="test"
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

source_tab=()

get_function $source_dir

echo "${#source_tab[@]}"

for i in ${source_tab}
do
  echo $i
done

echo "Secrets from destination directory"

function validation() {

  files=$(vault kv list $1)
  for file in $files
  do
    if [[ "$file" == */ ]];  then
      validation ${1}$file
    elif [[ "$file" != "Keys" && "$file" != "----" ]]; then
      echo "${1}$file"
      dest_tab=(${dest_tab[@]} ${1}$file)
    fi
  done
}

dest_tab=()

validation $dest_dir

echo "Number of secrets in source directory: ${#source_tab[@]}"

echo "Number of secrets in destination directory: ${#dest_tab[@]}"


if [[ ${#source_tab[@]} == ${#dest_tab[@]} ]]; then
  echo "Number of secrets is correct ${#source_tab[@]}"
else
  echo "Number of secrets is incorect"
fi


function compare_json() {

  for ((i = 0; i < ${#source_tab[@]}; ++i));
  do
    vault kv get -format=json ${source_tab[i]} | jq '.data."data"' > src.json
    vault kv get -format=json ${dest_tab[i]} | jq '.data."data"' > dst.json
    diff=$(diff <(jq -S . src.json) <(jq -S . dst.json))
    if [[ $diff == "" ]]; then
      echo "Equals"
    else
      echo "Not equals"
      vault kv get -format=json ${source_tab[i]}
      vault kv get -format=json ${dest_tab[i]}
    fi
  done

} 

compare_json
