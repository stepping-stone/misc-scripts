#!/bin/bash
################################################################################
# ucarp-hook-dispatcher.sh - UCARP up/down script dispatcher
################################################################################
#
# Copyright (C) 2013 stepping stone GmbH
#                    Switzerland
#                    http://www.stepping-stone.ch
#                    support@stepping-stone.ch
#
# Authors:
#  Christian Affolter <christian.affolter@stepping-stone.ch>
#  
# Licensed under the EUPL, Version 1.1.
#
# You may not use this work except in compliance with the
# Licence.
# You may obtain a copy of the Licence at:
#
# http://www.osor.eu/eupl
#
# Unless required by applicable law or agreed to in
# writing, software distributed under the Licence is
# distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
# See the Licence for the specific language governing
# permissions and limitations under the Licence.
#
# This is the UCARP up/down dispatch script which will be called by the ucarp 
# daemon whenever it switches its state (from backup to master for example).
#
# It executes all scripts located at
# /usr/libexec/ucarp-hooks/active/<INTERFACE-ALIAS>/{up,down}/*.sh
# and passes all received arguments to those scripts.
################################################################################

LIB_DIR=${LIB_DIR:="$(dirname $(readlink -f ${0}))/../../share/stepping-stone/lib/bash"}

export SYSLOG_TAG="ucarp-hook"

# Disable printing of messages
export IO_PRINT="no"
source "${LIB_DIR}/input-output.lib.sh"

# Set restrictive umask by default
umask 0077

# Patterns that match no files shall expand to zero arguments, rather than to
# themselves. 
shopt -s nullglob


function main ()
{
    local action="$1"
    local ifAlias="$2"
    local device="$3"
    local ip="$4"
    local prefix="$5"

    test -n "${action}"  || die "Missing action as the first argument"
    test -n "${ifAlias}" || die "Missing interface alias as the second argument"
    test -n "${device}"  || die "Missing device as the third argument"
    test -n "${ip}"      || die "Missing IP address as the fourth argument"
    test -n "${prefix}"  || die "Missing prefix as the fifth argument"

    if [ "${action}" != "up" ] && [ "${action}" != "down" ]; then
        die "Action (the first argument) has to be either 'up' or 'down'"
    fi

    # Set the (log) message prefix to include all the necessary informations to
    # identify a specific UCARP instance
    ioSetMessagePrefix "${ifAlias} ${action} -"

    local hookDir="$(readlink -f ${0%/*})/active/${action}/${ifAlias}"

    debug "Action:   '${action}'"
    debug "ifAlias:  '${ifAlias}'"
    debug "Device:   '${device}'"
    debug "IP:       '${ip}'"
    debug "Prefix:   '${prefix}'"
    debug "hook dir: '${hookDir}'"

    test -d "${hookDir}" || die "Missing hook directory: ${hookDir}"


    info "Executing hook script(s) for ${device}:${ip}/${prefix}"

    local hookCounter=0

    for hookScript in ${hookDir}/*.sh; do
        scriptName="$( basename ${hookScript} )"

        info "Executing hook script ${scriptName}"
        ${hookScript} $@ > /dev/null 2>&1 || \
            die "Hook script ${scriptName} failed with code $?"

        info "Execution of hook script ${scriptName} done"

        (( hookCounter++ ))
    done

    info "Successfully executed ${hookCounter} hook script(s)"
}


main "$1" "$2" "$3" "$4" "$5"
