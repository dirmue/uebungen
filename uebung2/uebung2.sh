#!/bin/bash

. ../lib/virtnet.sh

add_netns "BRIDGE1"
add_br "br0" "BRIDGE1"
run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "BRIDGE1"
open_term_netns "BRIDGE1" "BRIDGE1"

add_netns "BRIDGE2"
add_br "br0" "BRIDGE2"
run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "BRIDGE2"
open_term_netns "BRIDGE2" "BRIDGE2"

for i in {0..1}; do
    add_netns "CLIENT$i"
    connect_netns "CLIENT$i" "BRIDGE1" "eth0" "port$i"
    add_ip "192.168.0.$(($i+1))/24" "eth0" "CLIENT$i"
    br_add_if "br0" "port$i" "BRIDGE1"
    run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "CLIENT$i"
    open_term_netns "Client_$i" "CLIENT$i"
done

for i in {2..3}; do
    add_netns "CLIENT$i"
    connect_netns "CLIENT$i" "BRIDGE2" "eth0" "port$(($i-2))"
    add_ip "192.168.0.$(($i+1))/24" "eth0" "CLIENT$i"
    br_add_if "br0" "port$(($i-2))" "BRIDGE2"
    run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "CLIENT$i"
    open_term_netns "Client_$i" "CLIENT$i"
done

connect_netns "BRIDGE1" "BRIDGE2" "port3" "port3"
br_add_if "br0" "port2" "BRIDGE1"
br_add_if "br0" "port2" "BRIDGE2"

echo -n "Warte bis alle Terminals geschlossen sind..."
wait

for i in {0..3}; do
    del_netns "CLIENT$i"
done

del_netns "BRIDGE1"
del_netns "BRIDGE2"

echo "BYE!"
