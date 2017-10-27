#! /bin/sh

####
# ID for SSD
id=0x8cdf9d911c60
#id=0x8cdf9d911c62

####
# Mount point for the device
mnt=/mnt

#--------
echo "[I] STOP ENTER"

#fuser -km $mntpt
echo "Executing [ umount $mnt ]"
umount $mnt
echo "	return [$?]"

# Deleting SSD ID if the SSD is in any group_id.
# 4093 means the SSD does not belong to any group_id.
cd /opt/nec/eem/eemcli
python ./eemcli.py get --id $id | grep group_id | grep 4093
if [ $? -ne 0 ]; then
	echo "Executing [ python ./eemcli.py del_gid --id $id ]"
	python ./eemcli.py del_gid --id $id
	echo "	return [$?]"
else
	echo "	return [$_] : already out of any group_id"
fi

echo "[I] STOP EXIT [$?]"
exit 0