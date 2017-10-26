# EXPRESSCLUSTER Quick Start Guide for ExpEther Manager and I/O Box

# Product Versions
- ExpEther Manager **???**
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

3. Install ECX 

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
- Select start.sh then click [Edit]. Add below lines.

<!--
	*** TBD ***
-->

		#!/bin/bash

- Select stop.sh then click [Edit]. Add below lines.

		#!/bin/bash

- [Finish]

# Setup eemcli
## Configure /opt/nec/eem/eemcli/eemcli.conf to make eemcli command accessing to FIP
On all servers, change the line

		server_ip=127.0.0.1

to

		server_ip=192.168.40.4

# Setup failover group for EE I/O Box (SSD)

## Adding dependency for EEM
Right click [failover-ssd] > [Properties]
[Start Dependency] tab > select [failover-eem] > [Add] > [OK]
