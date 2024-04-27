#!/usr/bin/expect -f

set accel "[lindex $argv 0]"
set memstick "[lindex $argv 1]"
set image "[lindex $argv 2]"

puts "Accel    = $accel"
puts "Memstick = $memstick"
puts "Image    = $image"
puts "Hit \` when the login: prompt appears"
puts "Hit return to continue or Ctrl-C to stop"
expect_user -re "(.*)\n"

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
# Hit return at boot menu for default option
expect "*Autoboot in*"
send -- "\r"
interact ` return
send -- "root\r"
expect "*root@:~ #"
send -- "poweroff\r"
expect eof
