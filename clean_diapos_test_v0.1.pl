#!/usr/bin/perl -w

# THINK TO IMAGE WARNINGS BE4 
# RELEASE 4 WITH WITH SYNOLOGY NAS

use File::Compare;
use File::Basename;
use File::Path;
use File::Spec;
use File::Copy;
use File::Find;

# use strict;

my $nb_scans 			= 0;
my $nb_scans_in_error 	= 0;
my $nb_scans_mod 		= 0;
my $nb_total 			= 0;

my $dim_home;

my $target_file;
my $target_dir;

my $BACKUP_VOLUME = "/Volumes/BACKUP/";
my $BACKUP_DIR = "SAUVEGARDES/IMAGES";

my $ERROR_DIR = "ERROR_TEST";

my $CSV_EXPORT = "/Users/LochNessIT/Desktop/export_csv";

# my $REL_PICTURES_STEP_1_DIR = "/TEST/SCANS";
my $REL_PICTURES_STEP_2_DIR = "/MINOLTA/TEST";
# my $REL_PICTURES_STEP_2_DIR = "/MINOLTA/META";
my $REL_PICTURES_STEP_3_DIR = "/MINOLTA/POST";
my $REL_PICTURES_STEP_4_DIR = "/MINOLTA/TEMP";

### SUB ###

# With $var instead

sub mount_volume {
	my $volume = $_[0];
	my $cmd = `mount -t smbfs //192.168.1.10/BACKUP $BACKUP_VOLUME`;
}

sub file_exists {
	my $vol = $_[0]; 
	if (-e($vol)) {
		return 1;
	}
	else {
		return 0;
	}
}

sub print_nb_scans {
	print "PRINTING SCANS_DIRS and nb_scans \n";
	foreach my $dir (sort keys %SCANS_DIRS) {
		print "\t DIR \t [ ",$dir," ] \n";
	}
}

sub print_SCANS_DIRS {
	print "PRINTING SCANS_DIRS \n";
	foreach my $dir (keys %SCANS_DIRS) {
		print "\t DIR \t [ ",$dir,	"\t",$SCANS_DIRS{$dir}{dir_type},"\t",$SCANS_DIRS{$dir}{year},
									"\t",$SCANS_DIRS{$dir}{event_name},"\t",$SCANS_DIRS{$dir}{nb_scans},
									"\t",$SCANS_DIRS{$dir}{nb_other_scans},"\t",$SCANS_DIRS{$dir}{nb_images},
						" ] \n";
	}
}

sub export_csv {

	open(FILE, '>', $CSV_EXPORT) or die "Could not open file '$CSV_EXPORT'";		  

	foreach my $dir (keys %SCANS_DIRS) {
	        print FILE $dir,"\t",$SCANS_DIRS{$dir}{nb_scans},"\t",$SCANS_DIRS{$dir}{nb_images},"\n";
	}	
	close($CSV_EXPORT);		
}

# Called by File::Find and do not backup hidden files

# scans_dir : SCANS
# image_dir : META

# HASH SCANS_DIRS : {dir_name}, nb_scans

sub check_diapos {

	my $new_filename;
	my @new_filename;
	my $dir_type;
	my $dir_name;
	
	if ( !($_ =~ /^\./) ) {
		print "FILE : ",$File::Find::name,"\n";
		if ( -f $_ ) {
#			print "FILE : ",$File::Find::name,"\n";
			$nb_scans++;
			my @dirs = File::Spec->splitdir($File::Find::name);
#			print "DIRS : ",join("/",@dirs),"\n"; 
			if ( ($#dirs == ($dim_home+3)) && ($dirs[$dim_home+1] =~ /^([0-9]){4}$/) ) {
				# NO ERROR
#				print "NO ERROR","\n";
				$dir_type = $dirs[$dim_home];
				$dir_name = File::Spec->catdir($dirs[$dim_home+1],$dirs[$dim_home+2]);
				$new_filename = "";
			}
			else {
#				print "ERROR","\n";
				$nb_scans_in_error++;
				$dir_type = "ERROR_TEST";
#				$dirs[$dim_home] = "ERROR_META";
				@new_filename = splice @dirs,0,$dim_home;
#				print "NEW_FILENAME 1: ",join("/",@new_filename),"\n"; 
				shift @dirs;
				$dir_name = File::Spec->catdir(@dirs);
#				print "DIR_NAME : ",$dir_name,"\n"; 
				splice @new_filename, $dim_home, 0, $dir_type, $dir_name;
#				print "NEW_FILENAME 2: ",join("/",@new_filename),"\n"; 
			}

			my $rec;
			
#			print "DIM_HOME : "			,	$dim_home,"\t";
#			print "DIR_NAME : "			,	$dir_name,"\t";
#			print "DIR_TYPE : "			, 	$dir_type,"\n";
#			print "FILENAME : "			,	"\t\t",$File::Find::name,"\n";
#			print "NEW_FILENAME : "		,	"\t\t",join("/",@new_filename),"\n";

#			print "YEAR : "				,	$year,"\n";
#			print "EVENT_NAME : "		, 	$event_name,"\n";
#			print "NB_SCANS : "			, 	$nb_scans,"\n";
#			print "NB_OTHER_SCANS : "	, 	$nb_other_scans,"\n";
#			print "NB_IMAGES : "		, 	$nb_images,"\n";
			$rec->{dir_name} = $dir_name;
			$rec->{dim_home} = $dim_home;
			$rec->{dir_type} = $dir_type;
			$rec->{filename} = $File::Find::name;
			$rec->{new_filename} = join("/",@new_filename);
			$SCANS_DIRS{ $rec->{dir_name} } = $rec;	
		}
	}
}

sub clean_diapos {

	foreach my $file (keys %SCANS_DIRS) {
	    if ( $SCANS_DIRS{$file}{dir_type} eq $ERROR_DIR ) {
			my($filename, $dirs, $suffix) = fileparse($SCANS_DIRS{$file}{new_filename});
			if ( !(-e $dirs) ) {
				mkpath($dirs);
			}				 	    
	    	if ( move($SCANS_DIRS{$file}{filename},$SCANS_DIRS{$file}{new_filename}) ) {
	    		print "MOVING FILE : ",$SCANS_DIRS{$file}{filename},"\n";
	    		$nb_scans_mod++;
	    	}
#			print "FILE : ",$SCANS_DIRS{$file}{filename}, " -> ", $SCANS_DIRS{$file}{new_filename},"\n";

	    }	
	}
}

# Fonction qui si le nb_scans <> surtout > nb_images liste les images manquantes
# Fonction qui supprime les autres images scans <> ####.tiff de SCANS et les copie dans TEMP

### MAIN ###

my $scans_dir;
my %SCANS_DIRS;

print "Debug : START","\n";


if (! (-e $BACKUP_VOLUME) ) {
	my $res = `mkdir $BACKUP_VOLUME`;
	if ( -d $BACKUP_VOLUME ) {
		mount_volume($BACKUP_VOLUME);
	}
	else {
		print "Echec à la création de ",$BACKUP_VOLUME,"\n";	
	}
}	


my $ABS_PICTURES_STEP_2_DIR = File::Spec->catdir( $BACKUP_VOLUME, $BACKUP_DIR, $REL_PICTURES_STEP_2_DIR );	
my @ABS_PICTURES_STEP_2_DIR = File::Spec->splitdir( $ABS_PICTURES_STEP_2_DIR );

$dim_home = $#ABS_PICTURES_STEP_2_DIR;
# print "DIM home : ",$dim_home,"\n";	
	
#	find(\&print_dir, $ABS_PICTURES_STEP_1_DIR );
	
finddepth(\&check_diapos, $ABS_PICTURES_STEP_2_DIR );
finddepth(\&clean_diapos, $ABS_PICTURES_STEP_2_DIR );
	
	
print "Nb scans : ",$nb_scans,"\n";
print "Nb scans in error : ",$nb_scans_in_error,"\n";
print "Nb scans moved : ",$nb_scans_mod,"\n";



