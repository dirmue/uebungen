#!/bin/bash

. ../lib/virtnet.sh

add_netns "BRIDGE"
add_br "br0" "BRIDGE"
run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "BRIDGE"
open_term_netns "Bridge" "BRIDGE"

for i in {0..3}; do
    add_netns "CLIENT$i"
    connect_netns "CLIENT$i" "BRIDGE" "eth0" "port$i"
    br_add_if "br0" "port$i" "BRIDGE"
    run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "CLIENT$i"
    open_term_netns "Client_$i" "CLIENT$i"
done

echo -n "Warte bis alle Terminals geschlossen sind..."
wait

for i in {0..3}; do
    del_netns "CLIENT$i"
done

del_netns "BRIDGE"

echo "BYE!"
