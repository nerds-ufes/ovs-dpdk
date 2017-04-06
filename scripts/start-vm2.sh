# This script starts the VM using qemu, OvS and DPDK

rm -d /tmp/qemu_share2
mkdir /tmp/qemu_share2

echo "Starting VM2..."
$QEMU_DIR/qemu-system-x86_64 \
 -cpu host \
 -boot c \
 -hda /root/dpdk-ovs-utils/Ubuntu-Server-14.04-x64-2.img \
 -m 2048M \
 -smp 2 \
 --enable-kvm -name 'vm_2 (.164)' \
 -vnc :2 -pidfile /tmp/vm_2.pid \
 -drive file=fat:rw:/tmp/qemu_share2,snapshot=off \
 -monitor unix:/tmp/vm_2monitor,server,nowait \
 -chardev socket,id=char1,path=/usr/local/var/run/openvswitch/vhost-user2 \
 -netdev type=vhost-user,id=mynet1,chardev=char1,vhostforce \
 -device virtio-net-pci,mac=00:00:00:00:00:02,netdev=mynet1,id=net1 \
 -object memory-backend-file,id=mem,size=2048M,mem-path=/dev/hugepages,share=on \
 -numa node,memdev=mem -mem-prealloc &
echo "VM2 up and running."
