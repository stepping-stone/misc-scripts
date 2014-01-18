#!/bin/bash
################################################################################
# sst-firewall-vip.sh - VIP sst-netfilter rule management UCARP hook script
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
# This scripts loads and unloads the stepping stone firewall rules related to
# the virtual IP address. It only tries to load them if the sst-firewall init
# script was started (an thus respects non-sst environments).
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

echo "${LIB_DIR}/iptables.lib.sh" > /tmp/out.txt
source "${LIB_DIR}/iptables.lib.sh"

function isFirewallStarted()
{
    local initScript="/etc/init.d/sst-firewall"

    if test -x "${initScript}"; then
        ${initScript} status > /dev/null
        return $?
    fi

    return 1
}

function getHostChainPrefix ()
{
    if test -n "${UCARP_HOOK_HOST_CHAIN_PREFIX}"; then
        echo "${UCARP_HOOK_HOST_CHAIN_PREFIX}"
    else
        local name="$( hostname )"
        echo "${name//-/_}" # substitute dashes with underscores
    fi
}


function checkChainPresence ()
{
    local ifAlias="$1"
    local chainPrefix="$2"

    local allChains="check_lo_in
                     check_lo_out
                     check_${ifAlias}_in
                     g_${ifAlias}_in
                     g_${ifAlias}_out
                     ${chainPrefix}_${ifAlias}_in
                     ${chainPrefix}_${ifAlias}_out"

    local chain
    for chain in ${allChains}; do
        debug "Check if chain '${chain}' is present"
        if ! iptablesIsChainPresent "${chain}"; then
            error "Missing netfilter chain '${chain}'"
            return 1
        fi
    done

    debug "All required chains are present"
    return 0
}


function netfilterUp ()
{
    local device="$1"
    local ip="$2"
    local prefix="$3"
    local ifAlias="$4" # pub, int etc.
    local chainPrefix="$5" # vm_node_01 for example

    info "Bringing up netfilter rules for virtual IP address"

    checkChainPresence "$ifAlias" "$chainPrefix" || die "Missing chains"

    ${IPTABLES_CMD} -I check_lo_in  -s ${ip}/32 -j g_${ifAlias}_in 
    ${IPTABLES_CMD} -I check_lo_out -d ${ip}/32 -j g_${ifAlias}_out
    ${IPTABLES_CMD} -I check_${ifAlias}_in -s ${ip}/32 -j drop_src
     
    ${IPTABLES_CMD} -I g_${ifAlias}_in  -d ${ip}/32 -j ${chainPrefix}_pub_in
    ${IPTABLES_CMD} -I g_${ifAlias}_out -s ${ip}/32 -j ${chainPrefix}_pub_out
     
    ${IPTABLES_CMD} -I ${chainPrefix}_${ifAlias}_in  -s ${ip}/32 -j ACCEPT
    ${IPTABLES_CMD} -I ${chainPrefix}_${ifAlias}_out -d ${ip}/32 -j ACCEPT
}

function netfilterDown ()
{
    local device="$1"
    local ip="$2"
    local prefix="$3"
    local ifAlias="$4"     # pub, int etc.
    local chainPrefix="$5" # vm_node_01 for example

    info "Bringing down netfilter rules for virtual IP address"

    ${IPTABLES_CMD} -D check_lo_in  -s ${ip}/32 -j g_${ifAlias}_in
    ${IPTABLES_CMD} -D check_lo_out -d ${ip}/32 -j g_${ifAlias}_out
    ${IPTABLES_CMD} -D check_pub_in -s ${ip}/32 -j drop_src
     
    ${IPTABLES_CMD} -D g_${ifAlias}_in  -d ${ip}/32 -j ${chainPrefix}_pub_in
    ${IPTABLES_CMD} -D g_${ifAlias}_out -s ${ip}/32 -j ${chainPrefix}_pub_out
     
    ${IPTABLES_CMD} -D ${chainPrefix}_pub_in  -s ${ip}/32 -j ACCEPT
    ${IPTABLES_CMD} -D ${chainPrefix}_pub_out -d ${ip}/32 -j ACCEPT
}

function main ()
{
    local operation="$1"
    local ifAlias="$2"
    local device="$3"
    local ip="$4"
    local prefix="$5"

    if ! isFirewallStarted; then
        info "sst-firewall is not started, skipping VIP netfilter rules"
        return 0
    fi

    local chainPrefix="$( getHostChainPrefix )"
    debug "Host chain prefix: '${chainPrefix}'"

    checkChainPresence "$ifAlias" "$chainPrefix" || die "Missing chains"


    case ${operation} in
        up )
            netfilterUp "$device" "$ip" "$prefix" "$ifAlias" "$chainPrefix" \
                2> >(error -)
        ;;

        down )
            netfilterDown "$device" "$ip" "$prefix" "$ifAlias" "$chainPrefix" \
                2> >(error -)
        ;;

        * )
            debug "Ignoring operation '${operation}'"
        ;;

    esac
}


main "$1" "$2" "$3" "$4" "$5"
