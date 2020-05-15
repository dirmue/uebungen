#!/bin/bash

. ../lib/virtnet.sh

for i in {0..2}; do
    add_netns "BRIDGE$i"
	add_br "br0" "BRIDGE$i"
done

connect_netns "BRIDGE0" "BRIDGE1" "port0" "port0"
connect_netns "BRIDGE0" "BRIDGE2" "port1" "port1"
connect_netns "BRIDGE1" "BRIDGE2" "port1" "port0"

add_netns "CLIENT1"
add_netns "CLIENT2"
connect_netns "BRIDGE1" "CLIENT1" "port1" "eth0"
connect_netns "BRIDGE2" "CLIENT2" "port2" "eth0"

run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "CLIENT1"
run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "CLIENT2"

for i in {0..2}; do
	run_cmd_in_netns "sysctl net.ipv6.conf.all.disable_ipv6=1" "BRIDGE$i"
	for p in {0..2}; do
		br_add_if "br0" "port$p" "BRIDGE$i"
	done
done

#run_cmd_in_netns "bridge link set cost 8 dev port0" "BRIDGE0"
#run_cmd_in_netns "bridge link set cost 9 dev port1" "BRIDGE0"
#run_cmd_in_netns "bridge link set cost 10 dev port2" "BRIDGE0"
#
#run_cmd_in_netns "bridge link set cost 10 dev port0" "BRIDGE1"
#run_cmd_in_netns "bridge link set cost 5 dev port2" "BRIDGE1"
#
#run_cmd_in_netns "bridge link set cost 8 dev port0" "BRIDGE2"
#run_cmd_in_netns "bridge link set cost 8 dev port2" "BRIDGE2"
#
#run_cmd_in_netns "bridge link set cost 8 dev port0" "BRIDGE3"
#run_cmd_in_netns "bridge link set cost 9 dev port1" "BRIDGE3"
#run_cmd_in_netns "bridge link set cost 5 dev port2" "BRIDGE3"

add_ip "192.168.0.1/24" "eth0" "CLIENT1"
add_ip "192.168.0.2/24" "eth0" "CLIENT2"

for i in {0..2}; do
    open_term_netns "BRIDGE$i" "BRIDGE$i"
done
open_term_netns "CLIENT1" "CLIENT1"
open_term_netns "CLIENT2" "CLIENT2"

echo -n "Warte bis alle Terminals geschlossen sind..."
wait

for i in {0..3}; do
    del_netns "BRIDGE$i"
done

del_netns "CLIENT1"
del_netns "CLIENT2"

echo "BYE!"
