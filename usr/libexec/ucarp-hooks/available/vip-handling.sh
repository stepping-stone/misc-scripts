#!/bin/bash
################################################################################
# vip-handling.sh - Virtual IP handling UCARP hook script
################################################################################
#
# Copyright (C) 2014 stepping stone GmbH
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
# This script brings the virtual IP address of a UCARP instance up or down.
#
# To activate this script, symlink it to 
# /usr/libexec/ucarp-hooks/active/{up,down}/<INTERFACE-ALIAS>/XY-foo.sh
# Afterwards it will be invoked by the main script located at
# /usr/libexec/ucarp-hook-dispatcher.sh whenever the related UCARP switches its
# state.
################################################################################

#export DEBUG=yes
LIB_DIR=${LIB_DIR:="$(dirname $(readlink -f ${0}))/../../../share/stepping-stone/lib/bash"}

SYSLOG_TAG="${SYSLOG_TAG:="ucarp-hook"}"

source "${LIB_DIR}/input-output.lib.sh"


IP_CMD="${IP_CMD:="/bin/ip"}"

if ! test -x "${IP_CMD}"; then
    IP_CMD="/sbin/ip"

    if ! test -x "${IP_CMD}"; then
        die "Missing ip command: '${IP_CMD}'"
    fi
fi


function vipUp ()
{
    local device="$1"
    local ip="$2"
    local prefix="$3"

    info "Bringing up virtual IP address"
    
    if ${IP_CMD} addr add ${ip}/${prefix} dev "${device}"  2> >(error -); then
        info "Virtual IP address was brought up successfully"
        return 0
    else
        die "Unable to bring up virtual IP address"
    fi
}


function vipDown ()
{
    local device="$1"
    local ip="$2"
    local prefix="$3"

    info "Bringing down virtual IP address"
    
    if ${IP_CMD} addr del ${ip}/${prefix} dev "${device}" 2> >(error -); then
        info "Virtual IP address was brought down successfully"
        return 0
    else
        die "Unable to bring down virtual IP address"
    fi
}


function main ()
{
    local operation="$1"
    local ifAlias="$2"
    local device="$3"
    local ip="$4"
    local prefix="$5"

    case ${operation} in
        up )
            vipUp "$device" "$ip" "$prefix"
        ;;

        down )
            vipDown "$device" "$ip" "$prefix"
        ;;

        * )
            debug "Ignoring operation '${operation}'"
        ;;

    esac
}


main "$1" "$2" "$3" "$4" "$5"
