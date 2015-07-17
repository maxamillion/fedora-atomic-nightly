# fedora-atomic-nightly
Fedora Atomic Nightly Build Scripts

This repository will be for scripts to build nightly/dev builds of [Fedora Atomic](https://getfedora.org/en/cloud/download/atomic.html)


## build-iso.sh

Dependencies: `mock`

NOTE: this script should be run as sudo and not as root because [mock](https://fedoraproject.org/wiki/Mock?rd=Subprojects/Mock) requires the ability to drop privs

This script will use mock on a Fedora or CentOS machine to build the Fedora Atomic ISO installer.

By default it will place the result in `/var/www/html/composes/$(date +%Y-%m-%d)` but that and effectively everything else about the script can be modified using the variables at the top of the script.

## build-pxetolive.sh

Dependencies: `mock`, `virt-install`,`lorax`

NOTE: this script should be run as sudo and not as root because [mock](https://fedoraproject.org/wiki/Mock?rd=Subprojects/Mock) requires the ability to drop privs

The script will take the installer iso created by `build-iso.sh`, kickstart from the git repository and create live Atomic Host images that can be booted with PXE.

First stage of build is creating raw disk image with livemedia-creator (using virt-install) on build host. This requires lorax, libvirt, virt-install, and qemu-kvm packages installed. Second stage - building live images from raw disk image with livemedia-creator is done in mock. The result should be placed into `/var/www/html/composes/$(date +%Y-%m-%d)` tree in `pxetolive` subdirectory.

More info on PXE to Live Atomic: http://www.projectatomic.io/blog/2015/05/building-and-running-live-atomic/

## clean-isos.sh
Simple script to limit the number of historic composes to keep on disk. Defaults to 30, but is configurable. This should be run in root’s cron or in the cron of an user with sudo ALL
