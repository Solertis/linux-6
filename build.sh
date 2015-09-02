#!/bin/sh
# prerequisites: linux, wget, apt-get install squashfs-tools

export TCL_SERVER=http://tinycorelinux.net/6.x/x86_64

# generate ssh keypair
ssh-keygen -f hypercore.rsa -t rsa -N ''

# download everything
wget -c -P downloads/ \
  $TCL_SERVER/release/distribution_files/corepure64.gz \
  $TCL_SERVER/tcz/pkg-config.tcz \
  $TCL_SERVER/tcz/make.tcz \
  $TCL_SERVER/tcz/gcc.tcz \
  $TCL_SERVER/tcz/gcc_libs-dev.tcz \
  $TCL_SERVER/tcz/gcc_libs.tcz \
  $TCL_SERVER/tcz/glibc_base-dev.tcz \
  $TCL_SERVER/tcz/linux-3.16.2_api_headers.tcz \
  $TCL_SERVER/tcz/openssl-1.0.0.tcz \
  $TCL_SERVER/tcz/openssh.tcz \
  $TCL_SERVER/tcz/iproute2.tcz \
  $TCL_SERVER/tcz/wget.tcz

# install packages
for f in downloads/*.tcz; do echo "Unpacking $f" && unsquashfs -f -d dist $f; done

# enter dist folder
cd dist

# extract rootfs
zcat < ../downloads/corepure64.gz | sudo cpio -i -d

# enables terminal (i think, blindly copied from xhyve example)
sudo sed -ix "/^# ttyS0$/s#^..##" etc/securetty
sudo sed -ix "/^tty1:/s#tty1#ttyS0#g" etc/inittab

# configure ssh
sudo cp usr/local/etc/ssh/sshd_config_example usr/local/etc/ssh/sshd_config
sudo mkdir var/ssh
sudo chmod 0755 var/ssh
sudo mkdir -p home/tc/.ssh
sudo cp ../hypercore.rsa.pub home/tc/.ssh/authorized_keys

# leave dist
cd ../

# copy our files in
sudo rsync --recursive include/ dist

# repackage core into final output
(cd dist ; sudo find . | sudo cpio -o -H newc) | gzip -c > initrd.gz

# cleanup
sudo rm -rf dist

echo "done"
