#!/bin/bash

# define tools
# all must be installed

# Set standard variables
export STDTERM="xterm"
export TOPT_EXEC="-e"
export TOPT_TITLE="-T"
export TOPT_ADD="-fa Monospace -fs 16"

export IP=$(which ip)
export TC=$(which tc)
export BRCTL=$(which brctl)
export BRIDGE=$(which bridge)
export XTERM=$(which $STDTERM)
export PC=$PROMPT_COMMAND

export def_host_prefix="host"
export def_bridge_prefix="bridge"

# check if a tool is installed
# check_installed <tool>
check_installed()
{
    if [ -n "$1" ]
    then
        which $1 &>/dev/null
        if [ $? -ne 0 ]
        then
            echo "Error: $1 not installed!"
            exit 1
        fi
        return 0
    else
        return 1
    fi
}


# Returns true if parameter p is an unsigned number
# is_uint <p>
is_uint()
{
	if [ -n "$1" ]
	then
		echo $1 |grep -qE "^[0-9]{1,}$"
		if [ $? -eq 0 ]
		then
			return $(true)
		fi
	fi
	return $(false)
}


# Creates a named network name space
# add_netns <name>
add_netns()
{
    if [ -n "$1" ]
    then
        $IP netns add $1
        set_up_in_netns "lo" $1
		run_cmd_in_netns "sysctl net.ipv4.conf.default.ignore_routes_with_linkdown=1" $1
		run_cmd_in_netns "sysctl net.ipv4.conf.all.ignore_routes_with_linkdown=1" $1
        return $?
    else
        return 1
    fi
}

# Deletes a named network name space
# del_netns <name>
del_netns()
{
    if [ -n "$1" ]
    then
        $IP netns del $1
        return $?
    else
        return 1
    fi
}

# add a 802.1q VLAN sub-device with <vid> to <interface>
# add_vlan_subif <vid> <interface> <netns>
add_vlan_subif()
{
    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
    then
        run_cmd_in_netns "$IP l add link $2 name $2.$1 type vlan id $1" $3
        set_up_in_netns "$2.$1" $3 
        return $?
    else
        return 1
    fi
}

# set pvid for bridgeport <interface> (!only one pvid possible!)
# add_bridgeport_pvid <pvid> <interface> <tagged|untagged> <netns>
add_bridgeport_pvid()
{
    TAGGING="untagged"
    if [ $3 == "tagged" ] || \
       [ $3 == "Tagged" ] || \
       [ $3 == "TAGGED" ] || \
       [ $3 == "T" ] || \
       [ $3 == "t" ]
       then
           TAGGING="tagged"
    fi

    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ]
    then
        run_cmd_in_netns "$BRIDGE vlan add vid $1 pvid $TAGGING dev $2" $4
        return $?
    else
        return 1
    fi
}

# set membership vor vid for bridgeport <interface>
# add_bridgeport_vid <vid> <interface> <tagged|untagged> <netns>
add_bridgeport_vid()
{
    TAGGING="untagged"
    if [ $3 == "tagged" ] || \
       [ $3 == "Tagged" ] || \
       [ $3 == "TAGGED" ] || \
       [ $3 == "T" ] || \
       [ $3 == "t" ]
       then
           TAGGING="tagged"
    fi

    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ]
    then
        run_cmd_in_netns "$BRIDGE vlan add vid $1 $TAGGING dev $2" $4
        return $?
    else
        return 1
    fi
}

# unset membership vor vid for bridgeport <interface>
# del_bridgeport_vid <pvid> <interface> <netns>
del_bridgeport_vid()
{
    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
    then
        run_cmd_in_netns "$BRIDGE vlan del $1 dev $2" $3
        return $?
    else
        return 1
    fi
}

# creates a bridge device in netns and enables VLAN filtering
# add_br <name> <netns>
add_br()
{
    if [ -n "$1" ] && [ -n "$2" ]
    then
        run_cmd_in_netns "$IP link add name $1 type bridge stp_state 1 mcast_snooping 1" $2
        run_cmd_in_netns "$IP link set $1 type bridge vlan_filtering 1" $2
        set_up_in_netns $1 $2
        return $?
    else
        return 1
    fi
}

# Deletes a bridge device from netns
# del_br <name> <netns>
del_br()
{
    if [ -n "$1" ] && [ -n "$2" ]
    then
        set_down_in_netns $1 $2
        run_cmd_in_netns "$BRCTL delbr $1" $2
        return $?
    else
        return 1
    fi
}

# Attach an interface to a bridge in netns
# br_add_if <bridge> <interface> <netns>
br_add_if()
{
    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
    then
        run_cmd_in_netns "$BRCTL addif $1 $2" $3
        return $?
    else
        return 1
    fi
}

# Deletes an interface from a bridge in netns
# br_del_if <bridge> <interface> <netns>
br_del_if()
{
    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
    then
        run_cmd_in_netns "$BRCTL delif $1 $2" $3
        return $?
    else
        return 1
    fi
}


# Add an ip address to an interface in netns
# add_ip <ip/nm> <dev> <netns>
add_ip()
{
    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
    then
        run_cmd_in_netns "$IP addr add $1 dev $2" $3
        return $?
    else
        return 1
    fi
}

# Deletes an ip address from an interface in netns
# del_ip <ip/nm> <dev> <netns>
del_ip()
{
    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
    then
        run_cmd_in_netns "$IP addr del $1 dev $2" $3
        return $?
    else
        return 1
    fi
}

# Runs <command> in name space <netns>
# run_cmd_in_netns <command> <netns>
run_cmd_in_netns()
{
    if [ -n "$1" ] && [ -n "$2" ]
    then
        $IP netns exec $2 $1 &>/dev/null
        return $?
    else
        return 1
    fi
}

# enable <interface> in <netns>
# set_up_in_netns <interface> <netns>
set_up_in_netns()
{
    run_cmd_in_netns "$IP link set up dev $1" "$2"
    return $?
}

# disable <interface> in <netns>
# set_down_in_netns <interface> <netns>
set_down_in_netns()
{
    run_cmd_in_netns "$IP link set down dev $1" "$2"
    return $?
}

# connect two netns via veth devices
# connect_netns <netns1> <netns2> <veth1> <veth2>
connect_netns()
{
    if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ]
    then
        $IP link add $3 netns $1 type veth peer name $4 netns $2
        set_up_in_netns $3 $1
        set_up_in_netns $4 $2
        return $?
    else
        return 1
    fi
}


# add delay to an interface
# add_delay <interface> <netns> <delay> [<jitter> [<correlation>]]
add_delay()
{
	if [ -n "$3" ] && is_uint $3 && [ -n "$1" ] && [ -n "$2" ]
	then
		DELAY_PARAM="${3}ms"
		if [ -n "$4" ] && is_uint $4
		then
			DELAY_PARAM="$DELAY_PARAM ${4}ms"
		fi
		if [ -n "$5" ] && is_uint $5
		then
			DELAY_PARAM="$DELAY_PARAM ${5}%"
		fi
    	run_cmd_in_netns "$TC qdisc add dev $1 root netem delay $DELAY_PARAM" "$2"
	else
		return 1
	fi
}


# add loss to an interface
# add_loss <interface> <netns> <loss>
add_loss()
{
	if [ -n "$3" ] && is_uint $3 && [ -n "$1" ] && [ -n "$2" ]
	then
    	run_cmd_in_netns "$TC qdisc add dev $1 root netem loss ${3}%" "$2"
	else
		return 1
	fi
}


# add package corruption to an interface
# add_corrupt <interface> <netns> <corruption>
add_corrupt()
{
	if [ -n "$3" ] && is_uint $3 && [ -n "$1" ] && [ -n "$2" ]
	then
    	run_cmd_in_netns "$TC qdisc add dev $1 root netem corrupt ${3}%" "$2"
	else
		return 1
	fi
}


# add package duplicates to an interface
# add_duplicates <interface> <netns> <corruption>
add_duplicate()
{
	if [ -n "$3" ] && is_uint $3 && [ -n "$1" ] && [ -n "$2" ]
	then
    	run_cmd_in_netns "$TC qdisc add dev $1 root netem duplicate ${3}%" "$2"
	else
		return 1
	fi
}


# open xterm with a shell that is tied to netns
# open_shell_netns <title> <netns>
open_term_netns()
{
    if [ -n "$1" ] && [ -n "$2" ]
    then
        PC="$PROMPT_COMMAND"
        export PROMPT_COMMAND="echo +++++ $2 +++++"
        $XTERM $TOPT_ADD $TOPT_TITLE $1 $TOPT_EXEC "ip netns exec $2 /bin/bash" &>/dev/null &
        export PROMPT_COMMAND="$PC"
        return $?
    else
        return 1
    fi
}


if [ $EUID -ne 0 ]
then
	echo "This script must be run as root!"
	exit -1
fi

check_installed "ip"
check_installed "bash"
check_installed "brctl"
check_installed "$STDTERM"
sysctl net.ipv4.ip_fowarding=1
sysctl net.ipv4.conf.all.fowarding=1
sysctl net.ipv4.conf.default.fowarding=1
sysctl net.ipv6.conf.all.fowarding=1
sysctl net.ipv6.conf.default.fowarding=1
clear

# If an ascii network sketch exists, show it
# The name must be <script_name>.sketch
# e.g. if the script is named exmpl.sh, the
# sketch must be named exmpl.sh.sketch
[[ -r "$0.sketch" ]] && cat "$0.sketch" && echo ""
