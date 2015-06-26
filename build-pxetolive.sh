fed_ver="22"
fed_arch="x86_64"
fed_compose="$(date +%Y%m%d)"

# FIXME - update and use https://git.fedorahosted.org/cgit/spin-kickstarts.git/tree/fedora-cloud-atomic-pxetolive.ks
# This kickstart is for disk image instllation using installer iso
kickstart_name="fedora-atomic-pxe-live.ks"

mock_src="fedora-${fed_ver}-${fed_arch}"
mock_target="fedora-${fed_ver}-pxetolive-${fed_arch}"
mock_cmd="mock -r ${mock_target}"

build_deps="lorax"

atomic_dest="/atomic-repo"
atomic_pxetolive_dir="${atomic_dest}/${fed_ver}/Cloud_Atomic/${fed_arch}/pxetolive/"

http_root_dir="/var/www/html/composes"
http_compose_dir="${http_root_dir}/$(date +%Y-%m-%d)"

pxetolive_diskimage_log_dir="logs/pxetolive/diskimage"
pxetolive_liveimage_log_dir="logs/pxetolive/liveimage"

diskimage_name="fedora-atomic-pxetolive-disk-${fed_compose}.raw"
mock_diskimage_dir="/diskimage"
diskimage_dir="/var/tmp"

iso_name="Fedora-Cloud_Atomic-${fed_arch}-${fed_ver}-${fed_compose}.iso"

############## Build raw disk image on host
# We don't probably want to run virt-install in mock.

#### Copy iso to location accessible by virt
# FIXME can we set permissions somehow so we don't have to cp the iso?
cmd="cp ${http_compose_dir}/${fed_ver}/Cloud_Atomic/${fed_arch}/iso/${iso_name} /var/lib/libvirt/images"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

#### Start libvirtd
cmd="systemctl start libvirtd.service"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

#### Create raw disk image
cmd="livemedia-creator --make-disk --image-name=${diskimage_name} --iso=/var/lib/libvirt/images/${iso_name} --ks=${kickstart_name} --ram=1500 --vnc=spice"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

#### Create disk build logs dir
cmd="mkdir -p ${http_compose_dir}/${pxetolive_diskimage_log_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

#### Move livemedia-creator logs
cmd="cp livemedia.log program.log virt-install.log ${http_compose_dir}/${pxetolive_diskimage_log_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

#### Remove copy of iso image
cmd="rm /var/lib/libvirt/images/${iso_name}"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

############## Build live images in mock

if ! [[ -f /etc/mock/${mock_target}.cfg ]]; then
    cp /etc/mock/${mock_src}.cfg /etc/mock/${mock_target}.cfg
    printf \
        "config_opts['plugin_conf']['bind_mount_opts']['dirs'].append(('/dev', '/dev' ))\n" \
        >> /etc/mock/${mock_target}.cfg
    printf \
        "config_opts['plugin_conf']['bind_mount_opts']['dirs'].append(('${diskimage_dir}', '${mock_diskimage_dir}' ))\n" \
        >> /etc/mock/${mock_target}.cfg

    #FIXME (maybe?) this is a bit of a dirty hammer swing to set the buildroot name
    sed -i "s/${mock_src}/${mock_target}/g" /etc/mock/${mock_target}.cfg

fi

#### Clean previous environment and setup new one
${mock_cmd} --clean || exit 1
${mock_cmd} --init || exit 1
${mock_cmd} --install ${build_deps} || exit 1

#### Create destination directory
cmd="mkdir ${atomic_dest}"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

#### Create logdir
cmd="mkdir -p ${atomic_dest}/${pxetolive_liveimage_log_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

#### Build Atomic ISO installer
cmd="livemedia-creator \
     --make-ostree-live \
     --disk-image=${mock_diskimage_dir}/${diskimage_name} \
     --live-rootfs-keep-size \
     --resultdir=${atomic_pxetolive_dir} " || exit 1
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

#### Copy logs
cmd="cp livemedia.log program.log ${atomic_dest}/${pxetolive_liveimage_log_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${mock_cmd} --shell "${cmd}" || exit 1

cmd="mkdir -p ${http_compose_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

cmd="cp -r /var/lib/mock/${mock_target}/root/${atomic_dest}/* ${http_compose_dir}"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

cmd="chown -R apache:apache ${http_compose_dir}/*"
printf "RUNNINING CMD: ${cmd}\n"
${cmd}

# FIXME - do it
##### Remove raw disk image
#cmd="rm ${diskimage_dir}/${diskimage_name}"
#printf "RUNNINING CMD: ${cmd}\n"
#${cmd}
