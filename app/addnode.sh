#!/bin/bash

newid=$1
source ./config/envs
let to=$timeout/5
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

if [ "$newid" -le 100 ] || [ "$newid" -ge 255 ]
  then
    echo "ID number of new machine should be between 101 and 254"
    exit 1
fi

ping -c1 ${vmsubnet::-2}.$newid > /dev/null
if [ $? -eq 0 ]
  then
    echo "IP address being used"
    exit 1
fi

cat << EOF > proxclone
- hosts: localhost
  remote_user: root
  gather_facts: False
  tasks:
  - name: clonevm
    proxmox_kvm:
      api_user    : $proxmoxuser
      api_password: $proxmoxpass
      api_host    : $proxmoxhost
      clone       : clone
      vmid        : $templateid
      newid       : $newid
      name        : RancherNode$newid
      node        : $proxmoxnode
      storage     : $proxmoxstorage
      format      : qcow2
      timeout     : $timeout

  - name: run
    proxmox_kvm:
      api_user    : $proxmoxuser
      api_password: $proxmoxpass
      api_host    : $proxmoxhost
      vmid        : $newid
      node        : $proxmoxnode
      state       : started
EOF

trap 'abort' 0
set -e

status "Creating virtual machine" "2"

ansible-playbook proxclone

status "Server being waited" "2"

tc=0
while ! nc -z $templateip 22 2>/dev/null;
do
  if [ $tc -gt $to ]
    then
      echo -e  "\nServer connection timeout"
      status "Server connection timeout" "3"
      exit 1
  fi
  echo -n "."
  sleep 5
  ((tc=tc+1))
done
  echo -e "\nConnection successful"

ssh -i ./config/key -o "StrictHostKeyChecking no" rancher@$templateip << EOF
  sudo ros config set hostname RancherNode$newid
  sudo ros config set rancher.network.interfaces.eth0.address ${vmsubnet::-2}.$newid/24
EOF
ssh -i ./config/key -o "StrictHostKeyChecking no" rancher@$templateip "nohup sudo reboot &>/dev/null & exit"

status "Settings was made rebooting" "2"

echo "Rebooting"
tc=0
while ! nc -z ${vmsubnet::-2}.$newid 22 2>/dev/null;
do
  if [ $tc -gt $to ]
    then
      echo -e "\nServer connection timeout"
      status "Server connection timeout" "3"
      exit 1
  fi 
  echo -n "."
  sleep 5
  ((tc=tc+1))
done
  echo -e  "\nConnection succesful"

status "Docker being waited" "2"

ssh -i ./config/key -o "StrictHostKeyChecking no" rancher@${vmsubnet::-2}.$newid "wait-for-docker && $nodecommand"

rm proxclone

status "Kubernetes being waited" "2"
tc=0
while ! kubectl get nodes | grep 'ranchernode'$newid &> /dev/null;
do
  if [ $tc -gt $((to*3)) ]
    then
      echo -e "\nKubernetes timeout error"
      exit 1
  fi
  echo -n "."
  sleep 5
  ((tc=tc+1))
done

trap : 0

status "Working" "1"
echo "Done"
