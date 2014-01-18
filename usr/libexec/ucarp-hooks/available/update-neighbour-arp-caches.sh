#!/bin/bash
################################################################################
# update-neighbour-arp-caches.sh - Send unsolicited ARP update UCARP hook script
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
# This script sends unsolicited ARP neighbour updates. This updates or
# invalidates MAC entries on other devices within the same LAN. Otherwise the
# neighbours will have a stale MAC entry in their cache and thus try to access
# the VIP on the old UCARP master.
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

ARPING_CMD="${ARPING_CMD:="/sbin/arping"}"

source "${LIB_DIR}/input-output.lib.sh"



function sendUnsolicitedArpUpdates ()
{
    local device="$1"
    local ip="$2"
    local prefix="$3"

    info "Sending unsolicited ARP updates"
    
    ${ARPING_CMD} -c 5 -U -I "${device}" "${ip}" 2> >(error -) || \
        error "Unable to send ARP updates"

    return 0
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
            sendUnsolicitedArpUpdates "$device" "$ip" "$prefix"
        ;;

        down )
            info "Nothing to do"
        ;;

        * )
            debug "Ignoring operation '${operation}'"
        ;;

    esac
}


main "$1" "$2" "$3" "$4" "$5"
