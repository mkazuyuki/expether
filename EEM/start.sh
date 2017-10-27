#!/bin/sh
echo START

# Checking existing EEM
cd /opt/nec/eem/eemcli
python ./eemcli.py get_apiver
if [ $? -eq 0 ]; then
	echo "[E] EEM is running"
	exit 0
fi

# Start EEM
/opt/nec/eem/tomcat/bin/startup.sh
echo "RETURN [$?]"

# Wait for EEM running up
max=60
for ((i=0; i < $max; i++)); do
	python ./eemcli.py get_apiver
	if [ $? -eq 0 ]; then
		break
	fi
	echo RETRY
	sleep 1
done

echo "EXIT [$?]"
