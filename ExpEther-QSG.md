# EXPRESSCLUSTER Quick Start Guide for ExpEther Manager and I/O Box


This text descrives how to configure EXPRESSCLUSTER to make ExpEther Manager (EEM) and SSD in ExpEther I/O Box (XBOX) into HA clustering configuraiton.


# Overview

EEM must be the only one instance in the broadcast domain. EC will protect this and improve availability.
In addition, XBOX is configured as storage for business continuity by route switching (changing group id).

 
# Product Versions on the verification

- ExpEther Manager <font color=red>**???**</font>
- EXPRESSCLUSTER for Linux 3.3.5-1
- Red Hat Enterprise Linux Server 7.2

# Hosts Parameters example

Host Parameters

| Hostname	| IP Address	| Group ID	|
|:---		|:---		|:---		|
| eesv1 	| 192.168.40.1	| 50		|
| eesv2		| 192.168.40.2	| 150		|
| eesv3		| 192.168.40.3	| 250		|

- FIP resource uses 192.168.40.4

ID for SSD

|		| ID			|
|---		|---			|
| SSD #1	| 0x8cdf9d911c60	| 
| SSD #2	| 0x8cdf9d911c62	|

# Prerequisite
1. Setting up hardware

    - Servers with 40G NIC
    - Switch
    - EE I/O Box with SSD.

2. Install and configure OS.

   Optionally disalbe

    - selinux
    - firewalld

3. Install EE Manager 

	Edit configuration file of eemcli.py ( /opt/nec/eem/eemcli/eemcli.conf ) to make it access to FIP where EE Manager runs.
	On all servers, change the line in the file from

		server_ip=127.0.0.1

	to

		server_ip=192.168.40.4

4. Install ECX and configure

		# rpm -ivh expresscls.*.rpm
		# clplcnsc -i [base-license-file] -p BASE33
		# reboot

# Setup initial Cluster

On the client PC,

- Open Cluster Manager ( http://192.168.40.1:29003/ )
- Change to [Operation Mode] from [Config Mode]
- Configure the cluster *EE-Cluster* which have no failover-group.
    - Configure Heartbeat I/F
      - 192.168.40.1 , 192.168.40.2, 192.168.40.3 for primary interconnect
      
# Setup failover group for EE Manager

## Adding failover group
- Right click [Groups] in left pane > [Add Group]
- Set [Name] as [*failover-eem*] > [Next]
- [Next]
- [Next]
- [Finish]

## Adding FIP resource
- Right click [failover-eem] > [Add Resource]
- Select [floating ip resource] as Type > input [fip-eem] as Name > [Next]
- [Next]
- [Next]
- Input [192.168.40.4] as IP Address > [Finish]

## Adding execute resource
- Right click [failover-eem] in left pane > [Add Resource]
- Select [Type] as [execute resource] then click [Next]
- [Next]
- [Next]
- Select start.sh then click [Edit]. Edit as below.

		#!/bin/sh
		echo START

		# Start EEM
		/opt/nec/eem/tomcat/bin/startup.sh
		echo "failover-eem RETURN [$?]"

		# Wait for EEM running
		cd /opt/nec/eem/eemcli
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

- Select stop.sh then click [Edit]. Edit as below.

		#!/bin/sh
		echo STOP
		/opt/nec/eem/tomcat/bin/shutdown.sh
		echo "EXIT [$?]"

- [Finish]

## Apply the configuration
- Click [File] > [Apply Configuration]
- Reboot all servers and wait for the completion of starting of the cluster *failover-eem*

----

Procedure for configuring EE Manager Clsuter have completed here.

----


# Setup failover group for EE I/O Box (SSD)

## Adding failover group
- Right click [Groups] in left pane > [Add Group]
- Set [Name] as [*failover-ssd*] > [Next]
- [Next]
- [Next]
- [Finish]

## Adding execute resource
- Right click [failover-ssd] in left pane > [Add Resource]
- Select [Type] as [execute resource] then click [Next]
- [Next]
- [Next]
- Select start.sh then click [Edit]. Edit as below.

		#! /bin/sh
		#***************************************
		#*              start.sh               *
		#***************************************

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


- Select stop.sh then click [Edit]. Edit as below.

		#!/bin/sh

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
		# The device to be unmounted
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


- [Finish]

## Adding dependency for EE Manager
Right click [failover-ssd] > [Properties]
[Start Dependency] tab > select [failover-eem] > [Add] > [OK]

## Apply the configuration
- Click [File] > [Apply Configuration]
- Reboot all servers by "clpstdn -r" command and wait for the completion of starting of the cluster *EE-Cluster**
