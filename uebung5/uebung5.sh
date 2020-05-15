#!/bin/bash

. ../lib/virtnet.sh

add_netns "BRIDGE1"
add_br "br0" "BRIDGE1"
run_cmd_in_netns 'sysctl net.ipv6.conf.all.disable_ipv6=1' "BRIDGE1"
# open_term_netns "Bridge1" "BRIDGE1"

for i in {0..1}; do
    add_netns "CLIENT$i"
    connect_netns "CLIENT$i" "BRIDGE1" "eth0" "port$i"
    br_add_if "br0" "port$i" "BRIDGE1"
    run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "CLIENT$i"
    open_term_netns "Client_$i" "CLIENT$i"
done

add_netns "BRIDGE2"
add_br "br0" "BRIDGE2"
run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "BRIDGE2"
# open_term_netns "Bridge2" "BRIDGE2"

for i in {2..3}; do
    add_netns "CLIENT$i"
    connect_netns "CLIENT$i" "BRIDGE2" "eth0" "port$i"
    br_add_if "br0" "port$i" "BRIDGE2"
    run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "CLIENT$i"
    open_term_netns "Client_$i" "CLIENT$i"
done

add_netns "ROUTER1"
add_netns "ROUTER2"
add_netns "ROUTER3"

connect_netns "ROUTER1" "BRIDGE1" "eth0" "port2"
br_add_if "br0" "port2" "BRIDGE1"

connect_netns "ROUTER2" "BRIDGE2" "eth0" "port4"
br_add_if "br0" "port4" "BRIDGE2"

connect_netns "ROUTER1" "ROUTER2" "eth1" "eth1"
connect_netns "ROUTER3" "ROUTER1" "eth0" "eth2"
connect_netns "ROUTER3" "ROUTER2" "eth1" "eth2"

run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "ROUTER1"
run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "ROUTER2"
run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "ROUTER3"

open_term_netns "Router1" "ROUTER1"
open_term_netns "Router2" "ROUTER2"
open_term_netns "Router3" "ROUTER3"

echo -n "Warte bis alle Terminals geschlossen sind..."
wait

for i in {0..3}; do
    del_netns "CLIENT$i"
done

del_netns "ROUTER1"
del_netns "BRIDGE1"
del_netns "ROUTER2"
del_netns "BRIDGE2"
del_netns "ROUTER3"

echo "BYE!"
