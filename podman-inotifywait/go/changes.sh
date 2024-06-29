#!/bin/bash

# There is a /tmp/go.pid unless this is the first run of this script
if [ -f "/tmp/go.pid" ]; then
  echo "Killing go"
  # Die if we can't kill the running go
  kill -9 `cat /tmp/go.pid` || {
    echo "Cannot kill existing go process"
    exit 1;
  }
fi

# Run /app/main.go in background, die if an error occurs
/usr/local/go/bin/go run /app/main.go &
pid="$!"

if [ "$?" -gt 0 ]; then
  echo "Cannot go run /app/main.go"
  exit 2
fi
  
# Save pid of go
echo -n "$pid" > /tmp/go.pid || {
  echo "Cannot save go pid"
  exit 3
}
