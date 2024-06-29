#!/bin/bash

echo "Run program"
ls -l /app/main.go
/usr/local/go/bin/go run /app/main.go

sleep 5

echo "Run program"
ls -l /app/main.go
/usr/local/go/bin/go run /app/main.go

echo "Starting inotifywait"
inotifywait -mre modify,move,create,delete /app | 
  while read -r dir action file; do 
    echo "A change occurred for $dir, $action, $file"
  done || {
    echo "Cannot start inotifywait"
    exit 1
  }
}

echo "Exiting"
