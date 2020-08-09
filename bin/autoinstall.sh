#!/usr/bin/expect

set timeout 20

set cmd [lrange $argv 1 end]
set password [lindex $argv 0]

eval spawn $cmd
expect "username:"
send "admin\r";
expect "enter a new password:"
send "$password\r";
expect "confirm new password:"
send "$password\r";

interact
