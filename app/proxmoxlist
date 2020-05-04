#!/bin/bash
source ./config/envs
SERVER=$proxmoxhost
USERNAME=$proxmoxuser
PASSWORD=$proxmoxpass
FORMAT=json

TOKEN=`curl -s -k -d "username=$USERNAME&password=$PASSWORD" https://$SERVER:8006/api2/json/access/ticket | jq -r .data.ticket`
if [ "${PIPESTATUS[0]}" != "0" ]; then
    echo Auth failed
    exit 1
fi

function json() {
    if [ "$2" != "0" ]; then
	echo ","
    fi
    echo "{"
    echo "\"vmid\": \"$VMID\","
    echo "\"node\": \"$NODE\","
    echo "\"type\": \"$1\","
    echo "\"name\": \"$NAME\","
    echo "\"mac\": \"$HWADDR\""
    echo -n "}"
}

function start_json() {
    echo "["
}

function end_json() {
    echo "]"
}

start_$FORMAT
POS=0

NODES=`curl -s -k https://$SERVER:8006/api2/json/nodes -b "PVEAuthCookie=$TOKEN" | jq -r '.data[].node'`
for NODE in `echo $NODES`; do
    curl -s -k https://$SERVER:8006/api2/json/nodes/$NODE/lxc -b "PVEAuthCookie=$TOKEN" > /tmp/proxvm-lxc.json
    curl -s -k https://$SERVER:8006/api2/json/nodes/$NODE/qemu -b "PVEAuthCookie=$TOKEN" > /tmp/proxvm-qemu.json

    for VMID in `cat /tmp/proxvm-lxc.json | jq -r '.data[].vmid'`; do
        curl -s -k https://$SERVER:8006/api2/json/nodes/$NODE/lxc/$VMID/config -b "PVEAuthCookie=$TOKEN" > /tmp/proxvm-$VMID.json
        JSON=`cat /tmp/proxvm-lxc.json | jq -r ".data[] | select(.vmid | tonumber | contains($VMID))"`
        NAME=`echo $JSON | jq -r .name`
        NET=`cat /tmp/proxvm-$VMID.json | jq -r .data.net0`
        HWADDR=`echo $NET | sed -re "s/.*hwaddr=([a-zA-Z0-9:]+),[a-zA-Z0-9]+=.*/\1/g"`
        $FORMAT lxc $POS
        POS=`expr $POS + 1`
    done

    for VMID in `cat /tmp/proxvm-qemu.json | jq -r '.data[].vmid'`; do
	curl -s -k https://$SERVER:8006/api2/json/nodes/$NODE/qemu/$VMID/config -b "PVEAuthCookie=$TOKEN" > /tmp/proxvm-$VMID.json
        JSON=`cat /tmp/proxvm-qemu.json | jq -r ".data[] | select(.vmid | tonumber | contains($VMID))"`
        NAME=`echo $JSON | jq -r .name`
        NET=`cat /tmp/proxvm-$VMID.json | jq -r .data.net0`
        HWADDR=`echo $NET | sed -re "s/[a-zA-Z0-9]+=([a-zA-Z0-9:]+),.*/\1/g"`
        $FORMAT qemu $POS
        POS=`expr $POS + 1`
    done
done

end_$FORMAT

rm /tmp/proxvm-*.json
