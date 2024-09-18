# High Availability for GPU enabled VM by Discrete Device Assignment

<!--
現下 VM で GPU を使う方法に DDA (Discrete Device Assignment 所謂 PCI pass through) がある。
ExpEther による GPU のサーバー間付替えと、DDA による VM の GPU 有効化とを使用し、サーバー間で GPU 付きの VM をフェイルオーバーさせるクラスタを構成する。
これにより、GPU 付き VM 及び GPU を使うワークロードの高可用性が実現される。
このドキュメントは、その構成、設定手順を示す。
-->

DDA (Discrete Device Assignment, and known as PCI pass-through) is a way for VM to use GPU on it.
A cluster that failover GPU enabled VM between servers can be configured by leveraging GPU switch-over between servers using ExpEther and GPU assignment on a VM using DDA.
This results in high availability for GPU-enabled VMs and workloads that use GPU.
This document describes the configuration procedures of such a cluster.

<div align=right>2023.08.01 Miyamoto Kazuyuki</div>

----

## Overview

- EEM (ExpEther Manager) must be the only one instance in the broadcast domain.
- ECX runs on Windows and protects the Hyper-V VM.
- XBOX contains GPU. EEM switch over the connection between the server and the GPU. ECX initiates the switch over by communicating with EEM. 

```
	+--------+    +--------+    +--------+    +----------------------------------+
	| GBE    +----+ ms1    +----+ 100G   +----+ XBOX                             |
	| Switch |    |  ECX   |    | Switch |    |  GPU (Gigabite GeForce RTX 2060) |
	|        |    |   VM   |    |        |    +----------------------------------+  
	|        |    +--------+    |        |    
	|        |                  |        |
	|        |    +--------+    |        |
	|        +----+ ms2    +----+        |
	|        |    |  ECX   |    |        |
	|        |    |   (VM) |    |        |
	|        |    +--------+    |        |
	|        |                  |        |
	|        |    +--------+    |        |
	|        +----+ vmh20  +----+        |
	|        |    |   EEM  |    |        |
	|        |    |        |    |        |
	+--------+    +--------+    +--------+
```
## Product versions

- Windows Server 2022
- EXPRESSCLUSTER X 5.1 for Windows
- ExpEther Manager

## Configuration

| Hostname	| IPv4 address  | IPv6 address                  | Role
|-- 		|--		|--                             |--
| ms1   	| 192.168.0.130	| fe80::215:5dff:fe00:fa33%12   | Primary node
| ms2   	| 192.168.0.200	| fe80::215:5dff:fe00:fa33%10   | Secondary node
| hp1   	| 192.168.0.139 |                               | Hosting vmh20
| vmh20 	|               | fe80::215:5dff:fe00:fa33%14   | ExpEther Manager Server
| vme2  	|               |                               | The VM to be controlled

## Setup

On both servers in the cluster, disable PnP for the GPU and dismount the GPU.

```powershell
#
# Find the PCI Location Path and disable the Device
#

# Enumerate all PNP Devices on the system
$pnpdevs = Get-PnpDevice -presentOnly

# Select only those devices that are Display devices manufactured by NVIDIA for example
$gpudevs = $pnpdevs |where-object {$_.Class -like "Display" -and $_.Manufacturer -like "NVIDIA"}

# Select the location path of the first device that's available to be dismounted by the host.
$locationPath = ($gpudevs | Get-PnpDeviceProperty DEVPKEY_Device_LocationPaths).data[0]

# Disable the PNP Device
Disable-PnpDevice  -InstanceId $gpudevs[0].InstanceId

# Dismount the Device from the Host
Dismount-VMHostAssignableDevice -force -LocationPath $locationPath
```

Install ECX on primary and secondary node.

Configure 2 node cluster with the failover-group `Failover-vme2` and the shared-disk resource `sd-1` in the failover-group. In this validation, G: is a drive in the shared-disk.

Apply the configuration and Start the clustr.

Open Hyper-V Manager at primary node `ms1`, create the VM `vme2` to be controlled and export it on `G:\Hyper-V\vme2\` in the shared-disk. Import the VM on the same place.
- `Import Virtual Machine`
- Specify `G:\Hyper-V\vme2\` in `Locate Folder` > `Next`
- Select `Register the virtual machine in-place (use the existing unique ID)` > `Next`
- Specify `G:\Hyper-V\vme2\` in `Locate Virtual Hard Disks` > `Next`

Configure the VM for DDA to have enough Memory Mapped I/O Space.

```powershell
#Configure the VM for a Discrete Device Assignment
$vm = 	"vme2"
#Set automatic stop action to TurnOff
Set-VM -Name $vm -AutomaticStopAction TurnOff
#Enable Write-Combining on the CPU
Set-VM -GuestControlledCacheTypes $true -VMName $vm
#Configure 32 bit MMIO space
Set-VM -LowMemoryMappedIoSpace 3Gb -VMName $vm
#Configure Greater than 32 bit MMIO space (1024Mb * 3 + 512 Mb)
Set-VM -HighMemoryMappedIoSpace 33280Mb -VMName $vm
```

Configure the script resource `script-1` with the following scripts to manage GPU connection and VM start/stop.

- parameters.bat : Define environment variables for the scripts.
- start.bat : disconnect the GPU from the server where it has been connected, and connects it to the server that become active node.
- start.ps1 : import the VM, and attaches the GPU to it, and power on it.
- stop.bat : call stop.ps1.
- stop.ps1 : stop the VM, and detach the GPU from it, and export it.