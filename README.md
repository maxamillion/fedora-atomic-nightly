# fedora-atomic-nightly
Fedora Atomic Nightly Build Scripts

This repository will be for scripts to build nightly/dev builds of [Fedora Atomic](https://getfedora.org/en/cloud/download/atomic.html)

## build-iso.sh
NOTE: this script should be run as sudo and not as root because [mock](https://fedoraproject.org/wiki/Mock?rd=Subprojects/Mock) requires the ability to drop privs

This script will use mock on a Fedora or CentOS machine to build the Fedora Atomic ISO installer.

By default it will place the result in `/var/www/html/composes/$(date +%Y-%m-%d)` but that and effectively everything else about the script can be modified using the variables at the top of the script.

