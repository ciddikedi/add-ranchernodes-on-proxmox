#!/bin/bash
newid=$1
source ./config/envs
CN=`echo $masterip | cut -d . -f 4`

abort()
{
  awk -v var="$newid" -v var2="${vmsubnet::-2}" -v var3="$CN" 'BEGIN { s = var",RancherNode"var",Stopped,Worker,"var2"."var",3" } /'"$newid"'/ { $0 = s; n = 1 } 1; END { if(!n) print s }' ./data/nodes.csv > tmp && mv tmp ./data/nodes.csv
  echo "Operation stopped"
  exit 1
}

status()
{
  awk -v var="$newid" -v var2="${vmsubnet::-2}" -v var3="$CN" -v status="$1" -v statusid="$2" 'BEGIN { s = var",RancherNode"var","status",Worker,"var2"."var","statusid } /'"$newid"'/ { $0 = s; n = 1 } 1; END { if(!n) print s }' ./data/nodes.csv > tmp && mv tmp ./data/nodes.csv
}

if ! [ $# -eq 1 ]
  then
    echo "Use a valid variable"
    exit 1
fi

if [ "$1" -le 100 ] || [ "$1" -ge 255 ]
  then
    echo "ID number of new machine should be between 101 and 254"
    exit 1
fi

if [ $CN -eq $1 ]
  then
    echo "You can't delete master machine"
    exit 1
fi

grep $1 ./data/nodes.csv
if ! [ $? -eq 0 ];
  then
    echo "$1 of number machine is not avaible"
    exit 1
fi

awk -F, '{print $4}' ./data/nodes.csv | grep -q '2'
if [ $? -eq 0 ]
  then
    echo "There is an operation in progress"
    exit 1
fi

cat << EOF > proxstop
- hosts: localhost
  remote_user: root
  gather_facts: False
  tasks:
  - name: stopvm
    proxmox_kvm:
      api_user    : $proxmoxuser
      api_password: $proxmoxpass
      api_host    : $proxmoxhost
      vmid        : $1
      node        : $proxmoxnode
      state       : stopped
      force       : yes
      timeout     : $timeout
EOF

cat << EOF > proxdelete
- hosts: localhost
  remote_user: root
  gather_facts: False
  tasks:
  - name: deletevm
    proxmox_kvm:
      api_user    : $proxmoxuser
      api_password: $proxmoxpass
      api_host    : $proxmoxhost
      vmid        : $1
      node        : $proxmoxnode
      state       : absent
EOF

if [ "Stopped" == "$(awk -F , '$1 == "'"$newid"'" { print $3 }' ./data/nodes.csv)" ]
  then
    awk -F, '$1 != "'"$newid"'"' ./data/nodes.csv > tmp && mv tmp ./data/nodes.csv
    ansible-playbook proxstop
    ansible-playbook proxdelete
    echo "Stopped operation was deleted"
    exit 1
fi

trap 'abort' 0
set -e

status "Node being deleted from Kubernetes" "2"
kubectl delete node ranchernode$1

sleep 15

status "Virtual machine being deleted" "2"
ansible-playbook proxstop
ansible-playbook proxdelete

trap : 0

rm proxstop
rm proxdelete

awk -F, '$1 != "'"$newid"'"' ./data/nodes.csv > tmp && mv tmp ./data/nodes.csv

echo "Done"
