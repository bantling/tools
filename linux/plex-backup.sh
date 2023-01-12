#!/bin/bash

usage() {
	echo "$0 [ -c -m -s ]

Makes a backup of plex media on a zfs filesystem to a FAT filesystem mounted on /mnt/backup.

The -c option backs up the config dir, -s backs up all music/* dirs except for music/all, and -m backs up everything else.
If no options are passed, everything is backed up.

Since the config dir contains a lot of symbolic links, and strange filenames that are not accepted on FAT,
it is always backd up as a tar file, which is always recreated even if no changes have occurred.

The music/[everything except all] dirs are symbolic links used to create collections for each user without
havingmto copy files. They are backed up as empty dirs.

Some movies are larger than 4GB, the max file size on a FAT system. Such movies are split into max 4GB chunks
that are named filename-0, filename-1, etc (eg movie.mkv-0, movie.mkv-1, ...).

Asdide from config, file listings are created of both plex and backup, and diffs are used to determine what files
are new, updated, or removed, and are copied to or removed from backup as necessary.
"

exit
}

# Determine what ops to do
doconfig=0
domain=0
dosyms=0
err=0

while getopts ":cms" arg; do
	case $arg in
		c) doconfig=1;;
		m) domain=1;;
		s) dosyms=1;;
		*) err=1;;
	esac
done

[ "$err" -eq 1 ] && usage

[ "$doconfig$domain$dosyms" -eq 0 ] && {
	doconfig=1
	domain=1
	dosyms=1
}

# Remove old generated shell script, if any
rm -f /tmp/backup-ops.sh

[ "$doconfig" -eq 1 ] && {
	shift

	# Handle config dir specially, it has symlinks and long file names FAT can't handle.
	# Only copy files that do not exist, or have been changed.
	# Technically, tar contains multiple copies of files that have been changed.
	echo "Generating backup of config..."
	echo '( \
	echo Backing up config...; \
	cd /srv/plex/config; \
	find . -type f -print0 | xargs -0 tar -cf /mnt/backup/config.tar; \
)' >> /tmp/backup-ops.sh
}

[ "$domain" -eq 1 ] && {
	shift

	# Copy new  and updated files in other dirs to same structure on backup
	cd "`dirname "$0"`"
	for i in `ls /srv/plex | grep -Ev 'config|music'` music/all; do
		#### Generates file containing <mod time>:<path name> for all regular files on plex and backup.
		#### This scan is only for files < 4GB byte in size, as the maximum safe size for a FAT filesystem is 4GB - 1 byte.
		#### Files whose names end in a dash and digit (eg .mkv-0) are the result of splitting a big file, skip them.
		echo "Scanning $i..."
		(cd /srv/plex; find "$i" -type f -size -4294967296c -printf '%p:%TY-%Tm-%TdT%TI:%TM:00\n' | sort > /tmp/plex.txt)
		find "$i" -type f -size -4294967296c \! -name '*-[0-9]' -printf '%p:%TY-%Tm-%TdT%TI:%TM:00\n' | sort > /tmp/backup.txt

		# New files - create copies of above files with timestamp stripped for existence comparison
		awk -F: '{print $1}' /tmp/plex.txt > /tmp/plex-nodate.txt
		awk -F: '{print $1}' /tmp/backup.txt > /tmp/backup-nodate.txt
		comm -23 /tmp/plex-nodate.txt /tmp/backup-nodate.txt | \
			sed -r 's,(.*),echo "Copying new file \1"; install -pD "/srv/plex/\1" "/mnt/backup/\1",' >> /tmp/backup-ops.sh

		# Updated files - compare original files
		comm -13 /tmp/plex.txt /tmp/backup.txt | \
			awk -F: '{print $1}' | \
			sed -r 's,(.*),echo "Copying updated file \1"; install -pD "/srv/plex/\1" "/mnt/backup/\1",' >> /tmp/backup-ops.sh

		# Deleted files - compare no timestamp files
		comm -13 /tmp/plex-nodate.txt /tmp/backup-nodate.txt | \
			sed -r 's,(.*),echo "Removing deleted file \1"; rm "/srv/plex/\1",' >> /tmp/backup-ops.sh

		#### A second scan only for files that are >= 4GB byte in size (> 4GB - 1 byte), requiring the files to be split into at least two max 4GB -1 byte chunks.
		#### Search plex for movie file and use name as is (eg *.mkv)
		#### Search in backup for files exactly 4GB - 1 byte in size ending in -0 (eg *.mkv-0), which are the first chunk, and use that chunk's date, removing the -0 from the filename.
		(cd /srv/plex; find "$i" -type f -size +4294967295c -printf '%p:%TY-%Tm-%TdT%TI:%TM:00\n' | sort > /tmp/plex-big.txt)
		find "$i" -type f -size 4294967295c -name '*-0' -printf '%p:%TY-%Tm-%TdT%TI:%TM:00\n' | sed -r 's,(.*)-0:,\1:,' | sort > /tmp/backup-big.txt

		# New big files
		awk -F: '{print $1}' /tmp/plex-big.txt > /tmp/plex-nodate-big.txt
		awk -F: '{print $1}' /tmp/backup-big.txt > /tmp/backup-nodate-big.txt
		comm -23 /tmp/plex-nodate-big.txt /tmp/backup-nodate-big.txt | \
			sed -r 's,(.*),echo "Copying new big file \1"; mkdir -p $(dirname "/mnt/backup/\1"); split -da 1 -b 4294967295 "/srv/plex/\1" "/mnt/backup/\1-"; touch -r "/srv/plex/\1" "/mnt/backup/\1-0",' >> /tmp/backup-ops.sh

		# Updated big files
		comm -13 /tmp/plex-big.txt /tmp/backup-big.txt | \
			awk -F: '{print $1}' | \
			sed -r 's,(.*),echo "Copying updated big file \1"; mkdir -p $(dirname "/mnt/backup/\1"); split -da 1 -b 4294967295 "/srv/plex/\1" "/mnt/backup/\1-"; touch -r "/srv/plex/\1" "/mnt/backup/\1-0",' >> /tmp/backup-ops.sh

		# Deleted big files
		comm -13 /tmp/plex-nodate-big.txt /tmp/backup-nodate-big.txt | \
			sed -r 's,(.*),echo "Removing deleted big file \1"; rm "/srv/plex/\1"*,' >> /tmp/backup-ops.sh
	done
}

[ "$dosyms" -eq 1 ] && {
	echo "Generating empty folders for sym links..."

	#### Create music symlinks (every subfolder of music except all are artist/album symlinks) as empty dirs in backup
	# Search plex for symlinks, which are not the same as dirs, so are easy to find
	# Create dirs in backup, but add .lnk to dir name to distinguish it from backup dirs that are not symlinks in plex
	(cd /srv/plex; find music \! -path 'music/all*' -type l -printf '%p.lnk\n' | sort > /tmp/plex.txt)
	find music -type d -name '*.lnk' -print | sort > /tmp/backup.txt

	# New dirs
	comm -23 /tmp/plex.txt /tmp/backup.txt | \
		sed -r 's,(.*),echo "Creating dir \1"; mkdir -p "\1",' >> /tmp/backup-ops.sh

	# Deleted dirs
	comm -13 /tmp/plex.txt /tmp/backup.txt | \
		sed -r 's,(.*),echo "Removing dir \1"; rm -f "\1",' >> /tmp/backup-ops.sh
}

# Execute generated script
bash /tmp/backup-ops.sh

