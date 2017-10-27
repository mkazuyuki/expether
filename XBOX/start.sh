#! /bin/sh

####
# IP for Server
node1=192.168.40.1
node2=192.168.40.2
node3=192.168.40.3

####
# group_id for HBA
gid1=50
gid2=150
gid3=250

####
# ID for SSD
id=0x8cdf9d911c60
#id=0x8cdf9d911c62

####
# The device to be mounted
dev=/dev/nvme0n1p1
#dev=/dev/nvme1n1p1

####
# Mount point for the device
mnt=/mnt

#--------
echo "[I] failover-ssd START ENTER"

# Resolving Server and group_id for HBA
ip a | grep $node1/
if [ $? -eq 0 ]; then
	gid=$gid
else
	ip a | grep $node2/
	if [ $? -eq 0 ]; then
		gid=$gid2
	else
		ip a | grep $node3/
		if [ $? -eq 0 ]; then
			gid=$gid3
		fi
	fi
fi
echo "HBA GID = [$gid]"

cd /opt/nec/eem/eemcli

# Deleting group_id on SSD if it is assigned
python ./eemcli.py get --id $id | grep group_id | grep 4093
if [ $? -ne 0 ]; then
	echo "Execution [ python ./eemcli.py del_gid --id $id ]"
	python ./eemcli.py del_gid --id $id
	echo "	return [$?]"
fi

# Set group_id to SSD
echo "Execution [ python ./eemcli.py set_gid --gid $gid --id $id ]"
python ./eemcli.py set_gid --gid $gid --id $id
echo "	return [$?]"

# NOTE:
# if you've removed & then reallocated the SSD to the server using the command,
# you would need to rescan the PCIe bus, so that SSD is detected by server without the need of server restart.

echo "Execution RESCAN"
echo 1 > /sys/bus/pci/rescan
echo "	return [$?]"
echo "Execution [ mnt $dev $mnt ]"
mount $dev $mnt
echo "	return [$?]"

logger -t failover-ssd EXIT
echo "[I] failover-ssd START EXIT"
exit 0
