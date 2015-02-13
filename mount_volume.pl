#!/usr/bin/perl -w

# mount 

use strict;

my $mount_point = "/Volumes/BACKUP";

sub mount_volume {
	my $volume = $_[0];
	my $cmd = `mount -t smbfs //192.168.1.4/BACKUP $mount_point`;
	# Check OK
}

# MAIN

if ( -e($mount_point) ) {
	print $mount_point, "déjà monté !","\n";
}
else {
	if (! (-e $mount_point)) {
		my $res = `mkdir $mount_point`;
	# Check OK
		if ( -d $mount_point ) {
			mount_volume($mount_point);
		}
		else {
			print "Echec à la création de ",$mount_point,"\n";	
		}
	}
}	
	
