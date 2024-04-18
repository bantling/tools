#!/bin/zsh

thisDir="`dirname "$0"`"
latestVersion="`curl -so - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/" | grep "<a href" | tail -n 1 | grep -Eo '([0-9.]*)' | head -n 1`"
image="FreeBSD-$latestVersion-RELEASE-amd64-memstick.img"
dlSum="${image}.xz.sha512"
genSum="${dlSum}.gen"

[ -f "$image" ] || {
  # Remove any existing files (and checksums) except current version
  echo "Removing older images"
  find . -maxdepth 1 -type f -name 'FreeBSD*' \! -name "FreeBSD-$latestVersion*" -print0 | xargs -0 rm

  # Download latest image
  echo "Downloading the $latestVersion image"
  curl --progress-bar -Lo - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/$latestVersion/FreeBSD-$latestVersion-RELEASE-amd64-memstick.img.xz" > "$image.xz"
}

# Download the checksum if we don't have it
[ -f "$dlSum" ] || {
  echo "Downloading the $latestVersion checksum"
  curl -sLo - "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/$latestVersion/CHECKSUM.SHA512-FreeBSD-$latestVersion-RELEASE-amd64" | grep amd64-memstick.img.xz | awk '-F=' '{print $2}' | tr -d ' ' > "$dlSum"
}

# Generate our own sha512 checksum for comparison
[ -f "$genSum" ] || {
  sha512sum -b "$image.xz" | awk '{print $1}' > "$genSum"
}

# Compare two checksums, and die if they are different
diff "$dlSum" "$genSum" > /dev/null || {
  echo "Downloaded checksum does not match generated checksum"
  exit 1
}

# Decompress image
[ -f "$image" ] || {
  echo "Extracting"
  xz --verbose -d "$image.xz" || {
    echo "Failed to decompress $image.xz"
    [ ! -f rm "$image" ] || { rm "$image" }
  }
}
