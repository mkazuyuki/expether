# EXPRESSCLUSTER integration with ExpEther Manager for protecting GPU-enabled VMs

This memo describes how to realize failover of GVM[^1] on Hyper-V by EXPRESSCLUSTER, ExpEther and GPU in XBOX[^2].
EC improves availability of GVM.

DDA (Discrete Device Assignment, and known as PCI pass-through) is a way for VM to use GPU. A cluster that failover GVM between servers can be configured by leveraging GPU switch-over using ExpEther and GPU assignment on a VM using DDA. This results in high availability for GVM and workloads running on it.

The architecture of ExpEther [hardware](https://expether.org/technology.html#page1) and [software](https://expether.org/technology.html#page4) are well explained on the official web page.

## Overview

Starting `GVM1` on `sv1`

1. EC issues commands to EEM[^3] to connect `sv1` and `GPU1` in XBOX.
2. EC issues commands to Hyper-V to mount `GPU1` on `GVM1`. It uses PCI passthrough.

[^1]: the VM which GPU is enabled.
[^2]: I/O box of ExpEther
[^3]: ExpEther Manager

    +--------+    +---------+    +--------+    +-------+
    | GBE    +----+ sv1     +----+ 80G    +----+ XBOX  |
    | Switch |    |  GVM1   |    | Switch |    |  GPU1 |
    |        |    |  ECX    |    |        |    |  GPU2 |
    |        |    +---------+    |        |    +-------+
    |        |                   |        |
    |        |    +---------+    |        |
    |        +----+ sv2     +----+        |
    |        |    |  (GVM1) |    |        |
    |        |    |   ECX   |    |        |
    +--------+    +---------+    +--------+

## Product Versions on the verification

- EXPRESSCLUSTER for Windows 5.1
- Windows Server 2022 and Hyper-V

## Hosts Parameters example

Host Parameters

| Hostname | IP Address   | Group ID |
|:---      |:---          |:---      |
| sv1      | 192.168.40.1 | 50       |
| sv2      | 192.168.40.2 | 150      |

ID for GPUs

|        | ID             |
|---     |:---            |
| GPU #1 | 0x8cdf9d911c60 |
| GPU #2 | 0x8cdf9d911c62 |

## Prerequisite

1. Setting up hardware

    - Servers with 80G NIC
    - Switch
    - EE I/O Box with GPU.

2. Install and configure OS.

   On both servers in the cluster, disable PnP for the GPU and dismount the GPU to prepare using DDA.

   ```powershell
   #
   # Find the PCI Location Path and disable the Device
   #
   
   # Enumerate all PNP Devices on the system
   $pnpdevs = Get-PnpDevice -presentOnly
   
   # Select only those devices that are Display devices manufactured by NVIDIA for example
   $gpudevs = $pnpdevs | where-object {$_.Class -like "Display" -and $_.Manufacturer -like "NVIDIA"}
   
   # Select the location path of the first device that's available to be dismounted by the host.
   $locationPath = ($gpudevs | Get-PnpDeviceProperty DEVPKEY_Device_LocationPaths).data[0]
   
   # Disable the PNP Device
   Disable-PnpDevice  -InstanceId $gpudevs[0].InstanceId
   
   # Dismount the Device from the Host
   Dismount-VMHostAssignableDevice -force -LocationPath $locationPath
   ```

3. Install and configure EE Manager

4. Setup VM

   Open Hyper-V Manager at primary node `sv1`, create the VM `GVM1` to be controlled and export it. Import the VM on the shared-disk.

   - `Import Virtual Machine`
   - Specify `G:\Hyper-V\GVM1\` in `Locate Folder` > `Next`
   - Select `Register the virtual machine in-place (use the existing unique ID)` > `Next`
   - Specify `G:\Hyper-V\GVM1\` in `Locate Virtual Hard Disks` > `Next`

   Configure the VM for DDA to have enough Memory Mapped I/O Space.

   ```powershell
   # Configure the VM for a Discrete Device Assignment
   $vm = "GVM1"
   # Set automatic stop action to TurnOff
   Set-VM -Name $vm -AutomaticStopAction TurnOff
   # Enable Write-Combining on the CPU
   Set-VM -GuestControlledCacheTypes $true -VMName $vm
   # Configure 32 bit MMIO space
   Set-VM -LowMemoryMappedIoSpace 3Gb -VMName $vm
   # Configure Greater than 32 bit MMIO space (1024Mb * 3 + 512 Mb)
   Set-VM -HighMemoryMappedIoSpace 33280Mb -VMName $vm
   ```

5. Install and configure ECX

## Setup initial Cluster

On the client PC,

- Open Cluster Manager <http://192.168.40.1:29003>
- Change to [Operation Mode] from [Config Mode]
- Configure the cluster *GVM-Cluster* which have no failover-group.
  - Configure Heartbeat I/F
    - 192.168.40.1 , 192.168.40.2 for primary interconnect

## Setup failover group for GVM

### Adding failover group

### Adding execute resource

- Right click [failover-GVM1] in left pane > [Add Resource]
- Select [Type] as [execute resource] then click [Next]
- [Next]
- [Next]
- Select start.sh then click [Replace]
- Select `GVM/start.sh`
- Select stop.sh then click [Replace]
- Select `GVM/stop.sh`
- [Finish]

## Apply the configuration

- Click [File] > [Apply Configuration]
- Reboot all servers by `clpstdn -r` command and wait for the completion of starting of starting the cluster *failover-GVM1*
