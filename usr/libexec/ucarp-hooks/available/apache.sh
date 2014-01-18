#!/bin/bash
################################################################################
# apache.sh - Apache HTTPD UCARP hook script
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
# This script starts and stops the Apache HTTP server which listens on a virtual
# IP address managed by UCARP.
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

APACHE_INIT_SCRIPT="${APACHE_INIT_SCRIPT:="/etc/init.d/apache2"}"

source "${LIB_DIR}/input-output.lib.sh"



function apacheUp ()
{
    info "Starting Apache HTTP server daemon"
    
    if ${APACHE_INIT_SCRIPT} start  2> >(error -); then
        info "Apache HTTP server daemon started"
        return 0
    else
        die "Unable to start Apache HTTP server daemon"
    fi
}


function apacheDown ()
{
    info "Stopping Apache HTTP server daemon"
    
    if ${APACHE_INIT_SCRIPT} stop  2> >(error -); then
        info "Apache HTTP server daemon stopped"
        return 0
    else
        die "Unable to stop Apache HTTP server daemon"
    fi
}



function main ()
{
    local operation="$1"
    local ifAlias="$2"
    local device="$3"
    local ip="$4"
    local prefix="$5"


    test -x "${APACHE_INIT_SCRIPT}" || \
        die "Missing Apache init script '${APACHE_INIT_SCRIPT}'"

    case ${operation} in
        up )
            apacheUp
        ;;

        down )
            apacheDown
        ;;

        * )
            debug "Ignoring operation '${operation}'"
        ;;

    esac
}


main "$1" "$2" "$3" "$4" "$5"
