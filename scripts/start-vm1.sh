# This script starts the VM using qemu, OvS and DPDK

rm -d /tmp/qemu_share1
mkdir /tmp/qemu_share1

echo "Starting VM1..."
$QEMU_DIR/qemu-system-x86_64 \
 -cpu host \
 -boot c \
 -hda /root/dpdk-ovs-utils/Ubuntu-Server-14.04-x64.img \
 -m 2048M \
 -smp cores=4 \
 --enable-kvm -name 'vm_1 (.164)' \
 -vnc :1 -pidfile /tmp/vm_1.pid \
 -drive file=fat:rw:/tmp/qemu_share1,snapshot=off \
 -monitor unix:/tmp/vm_1monitor,server,nowait \
 -chardev socket,id=char1,path=/usr/local/var/run/openvswitch/vhost-user1 \
 -netdev type=vhost-user,id=mynet1,chardev=char1,vhostforce \
 -device virtio-net-pci,mac=00:00:00:00:00:01,netdev=mynet1,id=net1 \
 -object memory-backend-file,id=mem,size=2048M,mem-path=/dev/hugepages,share=on \
 -numa node,memdev=mem -mem-prealloc &
echo "VM1 up and running."

#-device pci-assign,host=02:00.3 \
