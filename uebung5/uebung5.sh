#!/bin/bash

. ../lib/virtnet.sh

add_netns "BRIDGE1"
add_br "br0" "BRIDGE1"

for i in {0..1}; do
    add_netns "CLIENT$i"
    connect_netns "CLIENT$i" "BRIDGE1" "eth0" "port$i"
    br_add_if "br0" "port$i" "BRIDGE1"
done

add_netns "BRIDGE2"
add_br "br0" "BRIDGE2"

for i in {2..3}; do
    add_netns "CLIENT$i"
    connect_netns "CLIENT$i" "BRIDGE2" "eth0" "port$i"
    br_add_if "br0" "port$i" "BRIDGE2"
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

add_ip "192.168.64.100/24" "eth0" "CLIENT0"
add_ip "192.168.64.200/24" "eth0" "CLIENT1"
add_ip "192.168.64.1/24" "eth0" "ROUTER1"

add_ip "192.168.128.100/24" "eth0" "CLIENT2"
add_ip "192.168.128.200/24" "eth0" "CLIENT3"
add_ip "192.168.128.1/24" "eth0" "ROUTER2"

add_ip "10.0.0.1/30" "eth1" "ROUTER1"
add_ip "10.0.0.2/30" "eth1" "ROUTER2"

add_ip "10.0.0.5/30" "eth2" "ROUTER1"
add_ip "10.0.0.9/30" "eth2" "ROUTER2"
add_ip "10.0.0.6/30" "eth0" "ROUTER3"
add_ip "10.0.0.10/30" "eth1" "ROUTER3"

run_cmd_in_netns "ip r add default via 192.168.64.1 dev eth0" "CLIENT0"
run_cmd_in_netns "ip r add default via 192.168.64.1 dev eth0" "CLIENT1"
run_cmd_in_netns "ip r add default via 192.168.128.1 dev eth0" "CLIENT2"
run_cmd_in_netns "ip r add default via 192.168.128.1 dev eth0" "CLIENT3"

# wieder löschen
run_cmd_in_netns "ip r add 192.168.128.0/24 via 10.0.0.6 metric 1" "ROUTER1"
run_cmd_in_netns "ip r add 192.168.128.0/24 via 10.0.0.2 metric 0" "ROUTER1"
run_cmd_in_netns "ip r add 192.168.64.0/24 via 10.0.0.10 metric 0" "ROUTER2"
run_cmd_in_netns "ip r add 192.168.64.0/24 via 10.0.0.1 metric 1" "ROUTER2"
run_cmd_in_netns "ip r add 192.168.64.0/24 via 10.0.0.5" "ROUTER3"
run_cmd_in_netns "ip r add 192.168.128.0/24 via 10.0.0.9" "ROUTER3"
#################

add_loss "eth0" "ROUTER3" "30"

clear

while [ "$OPT" != "Beenden" ]; do
	[[ -r "$0.sketch" ]] && cat "$0.sketch" && echo ""
	echo "Terminal öffnen für..."
	select OPT in CLIENT0 CLIENT1 CLIENT2 CLIENT3 ROUTER1 ROUTER2 ROUTER3 Beenden
	do
		case $OPT in
			Beenden) break ;;
			*) 	open_term_netns "$OPT" "$OPT" && \ 
				clear && \
				break ;;
		esac
	done
done

killall xterm &>/dev/null

for i in {0..3}; do
    del_netns "CLIENT$i"
done

del_netns "ROUTER1"
del_netns "BRIDGE1"
del_netns "ROUTER2"
del_netns "BRIDGE2"
del_netns "ROUTER3"

echo "BYE!"
