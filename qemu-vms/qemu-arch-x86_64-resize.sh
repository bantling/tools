#!/usr/bin/expect -f

# Call with two arguments:
# device to resize, eg /dev/vda
# partition to resize, eg 1

set timeout -1
spawn parted [lindex $argv 0]
match_max 100000
expect "*(parted) "
send "resizepart\r"
expect "*Fix/Ignore? "
send "f\r"
expect "*Partition number? "
send "[lindex $argv 1]\r"
expect "*Yes/No? "
send "y\r"
expect "*\]? "
send "100%\r"
expect "*(parted) "
send "p\r"
expect "*(parted) "
send "w\r"
expect "*(parted) "
send "q\r"
expect eof
