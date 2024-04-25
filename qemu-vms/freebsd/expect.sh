#!/usr/bin/expect -f

set accel "[lindex $argv 0]"
set memstick "[lindex $argv 1]"
set image "[lindex $argv 2]"

puts "Accel    = $accel"
puts "Memstick = $memstick"
puts "Image    = $image"

# Fire up qemu
spawn qemu-system-x86_64 \
  -accel "$accel" \
  -boot c \
  -cpu qemu64 \
  -m 1024 \
  -drive "file=$memstick,format=raw,if=virtio" \
  -drive "file=$image,format=raw,if=virtio" \
  -nographic

match_max 100000
expect "*Autoboot in*"
send -- "\r"
interact +++ return
send -- "root\r"
expect "*root@:~ #"
send -- "poweroff\r"
expect eof
