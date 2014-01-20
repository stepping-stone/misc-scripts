#!/bin/sh

# Call the UCARP hook-script dispatcher with the down event
# $1: device name, such as 'eth0'
# $2: virtual IP address, such as '192.0.2.10'
# $3: prefix length, such as '24' 
/usr/libexec/ucarp-hooks/ucarp-hook-dispatcher.sh down int "$1" "$2" "$3"
