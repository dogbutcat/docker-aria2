#!/bin/sh

finish(){
	echo "stopping aria2c"
	# kill nginx
	nginx -s stop
	# kill aria2 process
	kill -SIGTERM $(ps -e|grep aria2c|grep -v grep|awk '{print $1}');
	# exit 0;
}
trap finish SIGTERM SIGINT SIGQUIT

bt_tracker_list=""
another_tracker_list=""
config_file_tracker=""
get_latest_tracker_list(){
	# get custom tracker set first, append ',' to none empty line
	config_file_tracker=$(cat ./config/aria2.conf|grep ^bt-tracker|awk -F "=" '{print $2}'|awk NF|sed "s/$/,/")
	# retrieve lastest tracker list
	bt_tracker_list=$(wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt |awk NF|sed ":a;N;s/\n/,/g;ta") # if code between :a and ta succeed, goto label a
	another_tracker_list=$(wget -qO- https://trackerslist.com/all.txt |awk NF|sed ":a;N;s/\n/,/g;ta") # if code between :a and ta succeed, goto label a
}

get_latest_tracker_list

nginx

# revoke the program with child process
aria2c --disable-ipv6=true --bt-tracker=${config_file_tracker}${bt_tracker_list},${another_tracker_list} $@ 2>&1 &

# add this to avoid aria2c directly running under PID 1
# which `init` does not accept SIGTERM or SIGINT protected by kernel
# If we press Ctrl-C during this loop, sleep will receive the SIGINT and die from it (sleep does not catch SIGINT). 
# more info link here:
# http://yangxikun.com/docker/2018/02/16/docker-init-process.html
# http://mywiki.wooledge.org/SignalTrap
while sleep 3600 & wait $!; do :;done