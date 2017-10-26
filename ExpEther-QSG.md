# EXPRESSCLUSTER Quick Start Guide for ExpEther Manager and I/O Box

# Versions
- ExpEther Manager **???**
- EXPRESSCLUSTER for Linux 3.3.5-1
- Red Hat Enterprise Linux Server 7.2

# Prerequisite
1. Setting up hardware : Servers with 40G NIC, Switch, EE I/O Box with SSD.
2. Install and configure OS.

	2.1. Optionally disalbe
	- selinux
	- firewalld

# Setup failover group for EE Manager
## Adding FIP resource
- Right click [failover-eem] > [Add Resource]
- Select [floating ip resource] as Type > input [fip-eem] as Name > [Next]
- [Next]
- [Next]
- Input [192.168.40.4] as IP Address > [Finish]
## Adding EXEC resource

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
