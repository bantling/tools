#!/usr/bin/expect -f

# Fire up telnet
spawn telnet -e '`' localhost 2323

match_max 100000
expect "*escape character is '`'.*"
send -- "`"
sleep 1
send -- "quit\r"
expect eof
