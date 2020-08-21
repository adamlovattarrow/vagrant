#!/bin/bash

yum -y update
yum -y install https://yum.puppet.com/puppet6-release-el-7.noarch.rpm
#yum -y install http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install nfs-utils dhcp tftp tftp-server syslinux vsftpd xinetd
sudo cp /home/vagrant/dhcpd.conf  /etc/dhcp/dhcpd.conf
sudo cp /home/vagrant/tftp /etc/xinetd.d/tftp

#Configure NFS
systemctl start nfs-server
systemctl enable nfs-server
mkdir -p /nfsshare/ubuntu18
chown nfsnobody:nfsnobody /nfsshare
echo "/nfsshare *(ro)" >> /etc/exports
exportfs -r

# Copy contents of Ubuntu ISO to NFS share
mkdir -p /mnt/iso
mount -o loop /home/vagrant/ubuntu-18.04.4-live-server-amd64.iso /mnt/iso
rsync -avrP /mnt/iso/ /nfsshare/ubuntu18/
cp -v /home/vagrant/ubuntu.seed /nfsshare/ubuntu18/preseed/ubuntu.seed

# Configure network
mkdir -p /home/vagrant
yum install dhcp tftp tftp-server syslinux vsftpd xinetd -y
cp -v /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot
cp -v /usr/share/syslinux/menu.c32 /var/lib/tftpboot
cp -v /usr/share/syslinux/memdisk /var/lib/tftpboot
cp -v /usr/share/syslinux/mboot.c32 /var/lib/tftpboot
cp -v /usr/share/syslinux/chain.c32 /var/lib/tftpboot
mkdir -p /var/lib/tftpboot/pxelinux.cfg
mkdir -p /var/lib/tftpboot/networkboot/ubuntu18
cp -v /home/vagrant/default /var/lib/tftpboot/pxelinux.cfg/default
cp -v /home/vagrant/grub.cfg /var/lib/tftpboot/grub.cfg
cp -v /home/vagrant/linux /var/lib/tftpboot/networkboot/ubuntu18/linux
cp -v /home/vagrant/initrd.gz /var/lib/tftpboot/networkboot/ubuntu18/initrd.gz
systemctl start tftp
systemctl enable tftp
systemctl restart tftp
systemctl start xinetd
systemctl enable xinetd
systemctl start dhcpd.service
systemctl enable dhcpd.service
setenforce 0
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X
iptables -t nat -X
iptables -t mangle -X
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth1 -j ACCEPT
iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp -m udp --sport 53 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
systemctl start firewalld
systemctl enable firewalld
systemctl start firewalld
systemctl restart firewalld