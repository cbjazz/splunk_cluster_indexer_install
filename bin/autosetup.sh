#!/usr/bin/expect

set timeout 20

set cmd [lrange $argv 1 end]
set password [lindex $argv 0]

eval spawn $cmd
expect "username:"
send "admin\r";
expect "assword:"
send "$password\r";

interact
