## Set up hugepages
mkdir /dev/hugepages

# Mount 1GB hugepages for VM
echo 8 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages
mount -t hugetlbfs -o pagesize=1G none /dev/hugepages

# Mount 2MB hugepages for application
#echo 256 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
#mount -t hugetlbfs nodev /mnt/huge -o pagesize=2M

# Insert igb_uio module if it hasn't been loaded yet.

#modprobe vfio-pci

modprobe uio
insmod $DPDK_DIR/x86_64-native-linuxapp-gcc/kmod/igb_uio.ko

# Bind interfaces 1 e 2
$DPDK_DIR/tools/dpdk_nic_bind.py -b igb_uio 0000:02:00.0
$DPDK_DIR/tools/dpdk_nic_bind.py -b igb_uio 0000:02:00.1
