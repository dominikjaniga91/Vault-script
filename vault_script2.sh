#!/bin/bash

declare -a secret
declare -a secret3

get_function() {

FILES=$(vault kv list $1)

  for f in $FILES
  do
    if [[ "$f" == */ ]];  then
      get_function ${1}$f
    elif [[ "$f" != "Keys" && "$f" != "----" ]]; then
      secret=(${secret[@]} ${1}$f)
      line="${secret[i]}"
      replaced=${line/secret\//secret3/}
      vault kv get -format=json $line | jq '.data."data"' > vault.json
      vault kv put $replaced @vault.json
    fi
  done

}

get_function "secret/"


declare -a secret3

get_function2() {

FILES=$(vault kv list $1)
  
  for f in $FILES
  do
    if [[ "$f" == */ ]];  then
      get_function ${1}$f
    elif [[ "$f" != "Keys" && "$f" != "----" ]]; then
      secret3=(${secret3[@]} ${1}$f)
    fi
  done
}

get_function2 "secret3/"

for n in ${secret3[@]}; do
  echo $n
done

if [[ ${#secret[@]} == ${#secret3[@]} ]]; then
  echo "Number of secrets is correct ${#secret[@]}"
fi

