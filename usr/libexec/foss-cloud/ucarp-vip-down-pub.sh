#!/bin/sh
 
# Stop apache 
/etc/init.d/apache2 stop

# Bring down the virtual IP address
/sbin/ip addr del "$2"/"$3" dev "$1"
