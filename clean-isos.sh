#!/bin/bash
#
# clean-isos.sh
#
# Simple script to be run in cron or otherwise scheduled for nightly runs
# with the aim of trimming old iso builds output from build-iso.sh
#
# This should be in root's crontab, it will need root privs or in the crontab
# of an user with sudo ALL

#### Number of old composes we want to keep around
persist_limit="30"

http_root_dir="/var/www/html/composes"

builds=( ${http_root_dir}/* )
if [[ "${#builds[@]}" -gt "${persist_limit}" ]]; then
    for dir in ${builds[@]:${persist_limit}:${#builds[@]}}
    do
        printf "REMOVING OLD COMPOSE AT: %s\n" "${dir}"
        rm -fr ${http_root_dir}
    done

fi



