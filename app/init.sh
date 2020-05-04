#!/bin/bash

if test -f "./config/envs";
  then
    echo "yapilandirma dosyasi okundu"
  else
    echo "yapilandirma dosyasi mevcut degil"
    exit 1
fi

source ./config/envs
CN=`echo $masterip | cut -d . -f 4`

if test -f "./data/master.csv";
  then
    echo "master.csv dosyasi mevcut"
  else
    cat << EOF > ./data/master.csv
id,hostname,status,role,ip,statusid
$CN,RacherMaster,Calisiyor,Master,${vmsubnet::-2}.$CN,1
EOF
    echo "master.csv dosyasi olusturuldu"
fi

if test -f "./data/nodes.csv";
  then
    echo "nodes.csv dosyasi mevcut"
  else
    cat << EOF > ./data/nodes.csv
id,hostname,status,role,ip,statusid
EOF
    echo "nodes.csv dosyasi olusturuldu"
    if ! [ $# -eq 1 ]
      then
        exit 1
    fi
fi

python $1
