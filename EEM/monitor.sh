#!/bin/sh

# This script monitors EEM by checking whether get_apiver API can be used.

cd /opt/nec/eem/eemcli
python ./eemcli.py get_apiver
if [ $? -ne 0 ]; then
	echo "[E] EEM is not running"
	exit 1
fi
