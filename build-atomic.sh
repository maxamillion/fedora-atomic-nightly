#!/bin/bash
#
# build-atomic.sh
#
# Simple script to be run in cron or otherwise scheduled for nightly builds
# of Fedora Atomic for Project Atomic (http://www.projectatomic.io/)
#
# This should be in root's crontab, it will need root privs

##### DISCLAIMER #####
# This is meant for nightly dev-builds, I would not recommend anyone run this
# script on a production compose machine

fed_ver="22"
fed_arch="x86_64"
fed_compose="$(date +%Y%m%d)"

fed_atomic_git="https://git.fedorahosted.org/cgit/fedora-atomic.git"
fed_atomic_dir="/fedora-atomic"
fed_atomic_conf="fedora-atomic-docker-host.json"

spin_kick_git="https://git.fedorahosted.org/git/spin-kickstarts.git"
spin_kick_dir="/spin-kickstarts"
spin_kick_lorax_embed="atomic-installer/lorax-embed-repo.tmpl"
spin_kick_lorax_conf="atomic-installer/lorax-configure-repo.tmpl"

mock_src="fedora-${fed_ver}-${fed_arch}"
mock_target="fedora-${fed_ver}-compose-${fed_arch}"
mock_cmd="mock -r ${mock_target}"

build_deps="rpm-ostree lorax git"

atomic_dest="/atomic-repo"
atomic_images_dir="${atomic_dest}/${fed_ver}/Cloud_Atomic/${fed_arch}/os/images"
atomic_iso_dir="${atomic_dest}/${fed_ver}/Cloud_Atomic/${fed_arch}/iso/"

if ! [[ -f /etc/mock/${mock_target}.cfg ]]; then
    cp /etc/mock/${mock_src}.cfg /etc/mock/${mock_target}.cfg
    printf \
        "config_opts['plugin_conf']['bind_mount_opts']['dirs'].append(('/dev', '/dev' ))\n" \
        >> /etc/mock/${mock_target}.cfg

    #FIXME (maybe?) this is a bit of a dirty hammer swing to set the buildroot name
    sed -i "s/${mock_src}/${mock_target}/g" /etc/mock/${mock_target}.cfg

fi

#### Clean previous environment and setup new one
${mock_cmd} --clean || exit 1
${mock_cmd} --init || exit 1
${mock_cmd} --install ${build_deps} || exit 1

#FIXME - This isn't needed since/if we use the fedora atomic updates
#### Clone the Fedora fedora-atomic git repo
#cmd="git clone ${fed_atomic_git} ${fed_atomic_dir}"
#printf "RUNNINING CMD: ${cmd}\n"
#${mock_cmd} --shell "${cmd}" || exit 1
#
#cmd="pushd ${fed_atomic_dir}; \
#    git checkout f${fed_ver}; \
#    popd"
#printf "RUNNINING CMD: ${cmd}\n"
#${mock_cmd} --shell "${cmd}" || exit 1

#### Clone the Fedora spin-kickstarts git repo
cmd="git clone ${spin_kick_git} ${spin_kick_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

cmd="pushd ${spin_kick_dir}; \
    git checkout f${fed_ver}; \
    popd"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

#### Create destination directory
cmd="mkdir ${atomic_dest}"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

#### Create logdir
cmd="mkdir ${atomic_dest}/logs/"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

#FIXME - This isn't needed since/if we use the fedora atomic updates
#### Initialize local atomic tree
#cmd="ostree init --repo=${atomic_dest} --mode=archive-z2"
#printf "RUNNINING CMD: ${cmd}\n"
#${mock_cmd} --shell "${cmd}" || exit 1
#
#cmd="rpm-ostree compose tree --repo=${atomic_dest} \
#                    ${fed_atomic_dir}/${fed_atomic_conf}"
#printf "RUNNINING CMD: ${cmd}\n"
#${mock_cmd} --shell "${cmd}" || exit 1

#### Build Atomic ISO installer
cmd="lorax --nomacboot -p Fedora -v ${fed_ver} \
    -r ${fed_compose} \
    -s https://dl.fedoraproject.org/pub/fedora/linux/releases/${fed_ver}/Everything/${fed_arch}/os/ \
    -s https://dl.fedoraproject.org/pub/fedora/linux/updates/${fed_ver}/${fed_arch}/ \
    -i fedora-productimg-atomic \
    -t Cloud_Atomic \
    --tmp /tmp/ \
    --logfile=${atomic_dest}/logs/atomic \
    --add-template ${spin_kick_dir}/${spin_kick_lorax_conf} \
    --add-template-var=ostree_osname=fedora-atomic \
    --add-arch-template-var=ostree_repo=https://dl.fedoraproject.org/pub/fedora/linux/atomic/${fed_ver}/ \
    --add-template-var=ostree_ref=fedora-atomic/f${fed_ver}/${fed_arch}/docker-host \
    --add-arch-template=${spin_kick_dir}/${spin_kick_lorax_embed} \
    --add-arch-template-var=ostree_osname=fedora-atomic \
    --add-arch-template-var=ostree_ref=fedora-atomic/f${fed_ver}/${fed_arch}/docker-host \
    ${atomic_dest}/${fed_ver}/Cloud_Atomic/${fed_arch}/os/ " || exit 1
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

cmd="mkdir ${atomic_iso_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

cmd="cp -l ${atomic_images_dir}/boot.iso \
    ${atomic_iso_dir}/Fedora-Cloud_Atomic-${fed_arch}-${fed_ver}-${fed_compose}.iso"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

cmd="pushd ${atomic_dest}/${fed_ver}/Cloud_Atomic/${fed_arch}/iso/ ; \
    sha256sum -b --tag *iso >Fedora-Cloud_Atomic-${fed_arch}-${fed_ver}-${fed_compose}-CHECKSUM; \
    popd"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

