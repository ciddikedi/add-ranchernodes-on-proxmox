#!/bin/bash

if test -f "./config/envs";
  then
    echo "Configuration file was read"
  else
    echo "Configuration file not found"
    exit 1
fi

source ./config/envs
CN=`echo $masterip | cut -d . -f 4`

if test -f "./data/master.csv";
  then
    echo "master.csv file is avaible"
  else
    cat << EOF > ./data/master.csv
id,hostname,status,role,ip,statusid
$CN,RancherMaster,Working,Master,${vmsubnet::-2}.$CN,1
EOF
    echo "master.csv file was created"
fi

if test -f "./data/nodes.csv";
  then
    echo "nodes.csv file is avaible"
  else
    cat << EOF > ./data/nodes.csv
id,hostname,status,role,ip,statusid
EOF
    echo "nodes.csv file was created"
    if ! [ $# -eq 1 ]
      then
        exit 1
    fi
fi

python $1
