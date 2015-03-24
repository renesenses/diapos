#!/usr/bin/perl -w

# Test mount

my $BACKUP_VOLUME = "/Volumes/BACKUP";

sub mount_volume {
	if ( !(-d $BACKUP_VOLUME) )  {
		system(`mkdir $BACKUP_VOLUME`);
	}
	else {
		system(`mount_afp -i afp://admin:ac2356\@192.168.1.10/BACKUP $BACKUP_VOLUME`);	
		if (-e "/Volumes/BACKUP/SAUVEGARDES" ) {
			return "CONNECTE AU NAS \n"; 
		}
		else {
			return "NAS INTROUVABLE \n";
		}	
	}
}

# MAIN

print mount_volume;
