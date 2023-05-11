# 2023.05.09

Windows 10,11 では GPU-PV (Para Virtualization) と GPU-P (Partitioning) とで GVM を[実現できる](https://qiita.com/Hyper-W/items/e189790fd4534d9d51ad)。Officially supported or not is unknown.

# 2023.04.26

ESXi + NVIDIA vGPU で GVM の Live Migration は[可能](https://docs.vmware.com/jp/VMware-vSphere/7.0/com.vmware.vsphere.vcenterhost.doc/GUID-8FE6A0DA-49E9-472B-815B-D630CF2014AD.html)


# 2023.04.21

## 目下可能と思われる方式

1. VM 起動前に(スクリプトで) GPU を付ける
2. VM を起動する
3. VM を停止する
4. VM 停止後に(スクリプトで) GPU を外す
5. move-vm で VM を移動させる
6. EE で GPU を付け替える
7. VM 起動前にスクリプトで GPU を付ける。
8. VM を起動する

SR-IOV で GPU 仮想化を目指す人々は[いる](https://open-iov.org/index.php/GPU_Support)。

SR-IOV で仮想化した NIC を持つ ECX 入り VM の vMotion は ESXi6 当時でも可能だった。

WS2022 で SR-IOV で仮想化したデバイスを持つ VM の LM が可能と思われる情報だが、[これ](https://learn.microsoft.com/ja-jp/windows-hardware/drivers/network/sr-iov-vf-failover-and-live-migration-support)は NIC を前提にしたものだった。  
では GPU を前提にした情報は無いか? > 今のところ見つからない。

GPU 仮想化コミュニティーに Open-IOV がある。
- https://open-iov.org/index.php/GPU_Support
- https://open-iov.org/index.php/Hypervisor_Support
- https://open-iov.org/index.php/Virtual_I/O_Internals
- https://open-iov.org/index.php/Glossary

# 2023.04.19

## 問題 : GPU enabled VM の LM を実現したい

問題を細分化する。VM に GPU を付ける方法には、PCI passthrough と NVIDIA vGPU とがある。

1. NVIDIA vGPU
    1. ESXi : [解あり](https://docs.vmware.com/jp/VMware-vSphere/7.0/com.vmware.vsphere.vcenterhost.doc/GUID-8FE6A0DA-49E9-472B-815B-D630CF2014AD.html)
    2. KVM  : **解あるかも**
    3. Hyper-V : 目下解無し。vGPU が Hyper-V をサポートしていない。

2. PCI passthrough  
   Hypervisor が GPUMEM のマイグレーションをケアしないような気がする。要調査。
    1. ESXi
    2. KVM
    3. Hyper-V

上記 1.2. について、以下に調査の余地がありそう。
1. WSL で KVM + NVIDIA vGPU の可否 (これは趣味レベル)
2. Linux VM on Hyper-V で KVM + NVIDIA vGPU をやってみる。

   KVM on Linux PM でやれば済むので、Hyper-V を使うためだけの理由で これをやるこに意味があるとも思えないが、目下 Hyper-V を使いつつ GPU VM の LM まで辿り着くことに明らかな不可能が見えない選択肢として 2. は調査の余地がある。

PCI passthrough (GPU-PV:GPU paravirtualization || DDA:Discreet Device Assignment) で Linux VM に GPU を見せる > 当該 VMで KVM + NVIDIA vGPU が使えるか調べる > 使えるなら vGPU を含めた LM の可否を調べる。

Hyper-V上の CentOS 8 で KVM を使うところまでは[検証](https://qiita.com/naoki-iso/items/821b98ccdf719dbd329a)がある。

libvert の virsh コマンドには migration オプションがあり、QEMU KVM での live migration は実現されている。

## vGPU VM on Hyper-V is N/A
NVIDIA は 仮想GPUドライバ (NVIDIA vGPU Software) を売っていて、VMware、Citrix、Red Hat、Nutanix をサポートしている。
(つまり、ESXi、Xen、KVM、AHV(KVM base))
問題はこれに Windows Hyper-Vが入っていないこと。
Hyper-v に於ける GPU enabled VM は、GPU Passthrough が可能、NVIDIA vGPU が不可能。

## KVM で *vGPU enabled VM* の LM は可能か?
`virsh migration` コマンドで VM の LM は可能な様子。
要調査

## ( KVM + vGPU ) on WSL は可能か?
WSLg によって *GPU enabled App on WSL2* は可能な様子。

QEMU の migration に関する document [[2]]

[2]:https://www.qemu.org/docs/master/devel/migration.html


# References
Christopher Clark, Keir Fraser, Steven Hand, Jacob Gorm Hansenf ,
Eric Julf , Christian Limpach, Ian Pratt, Andrew Warfield. Live Migration of Virtual Machines
NSDI 2005 (Networked Systems Design & Implementation 2005) [[11]]

[11]:https://www.usenix.org/legacy/event/nsdi05/tech/full_papers/clark/clark_html/

Aidan Shribman & Benoit Hudzia.
Pre-Copy and Post-Copy VM Live Migration for Memory Intensive Applications.
*Virtual Execution Environments 2009* [[12]]

[12]:https://link.springer.com/chapter/10.1007/978-3-642-36949-0_63


Hines, M., and Gopalan, K. Post-copy based live
virtual machine migration using adaptive pre-paging
and dynamic self-ballooning. In Proceedings of ACM
SIGPLAN/SIGOPS International Conference on
Virtual Execution Environments (VEE), Washington,
DC (March 2009) [[13]].

[13]:https://dl.acm.org/doi/10.1145/1508293.1508301

Michael R. Hines, Umesh Deshpande, and Kartik Gopalan. Post-Copy Live Migration of Virtual Machines (2009) [[14]].

[14]:[https://kartikgopalan.github.io/publications/hines09postcopy_osr.pdf]

QEMU > Developer Information > Internal Subsystem Information > [Migration](https://www.qemu.org/docs/master/devel/migration.html)

[VirGL](https://docs.mesa3d.org/drivers/virgl/)

