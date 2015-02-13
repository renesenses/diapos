#!/usr/bin/perl -w

# THINK TO IMAGE WARNINGS BE4 

use Image::ExifTool;

use File::Compare;
use File::Basename;
use File::Path;
use File::Spec;
use File::Copy;
use File::Find;
# use strict;

my $nb_images = 0;
my $new_number =1;

my $target_file;
my $target_dir;

my $BACKUP_VOLUME = "/Volumes/BACKUP/";
my $BACKUP_DIR = "BACKUPS";

my $REL_PICTURES_STEP_1_DIR = "Pictures/MINOLTA/SCANS";
my $REL_PICTURES_STEP_2_DIR = "Pictures/MINOLTA/META";
my $REL_PICTURES_STEP_3_DIR = "Pictures/MINOLTA/POST";

### SUB ###

# With $var instead

sub mount_volume {
	my $volume = $_[0];
	my $cmd = `mount -t smbfs //192.168.1.4/BACKUP $BACKUP_VOLUME`;
}

sub is_an_image_file {
	my $file = $_[0]; 
#	print "DOLLAR_FILE : ",$file, "COMP_EXT : ",compute_file_extension($file),"\n"; 
	if ( (compute_file_extension($file) eq "tiff") || (compute_file_extension($file) eq "jpeg") ) {
		$nb_images++;
		return 1;
	}
	else {
		return 0; 
	}
}

sub increment_file_number {
	my $fullname = $_[0];
	my $version;
	my ($file,$dir,$ext) = fileparse($fullname, qr/\.[^.]*/);
	if ($file =~ /([0-9])$/ ) {
		$version = $1;
		$file = substr($file,0,length($file)-length($version));
		$version++;
		return($dir.$file.$version.$ext);
	}
}



sub increment_filename_version {
	my $fullname = $_[0];
	my $version;
	my ($file,$dir,$ext) = fileparse($fullname, qr/\.[^.]*/);
	if ($file =~ /_v([0-9]{3}$)/ ) {
		$version = $1;
		$file = substr($file,0,length($file)-3);
		$version++;
	}
	else {
		$version ="_v001";
	}
	return($dir.$file.$version.$ext);
}

# ORDER_OK IF 
# if check number_length OK
#	order; take first file put number to 001 ; increment
# if number length NOK
# 	order sur les 2 derniers digits puis sur date de création

# double le classification
# test par groupe de taille inférieure ou égal à 4 fichiers

sub order_and_number_file {
	my $dir ;
	
#	print "ORDER BEGIN",$_,"\n";
	if ( !($_ =~ /^\./) ) {
		if ( -d $File::Find::name ) { 
			$new_number = 1;
    		$dir = $File::Find::dir;
#    		print "DOLLAR_DIR",$dir,"\n";
    	}	
    	else { 
#    		print "DOLLAR_DIEZE : ",$_,"\n"; 
    		my ($filename,$_dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
    		if ($filename =~ /([0-9]+)$/) { 
    			my $file_num = $1;
    			$filename = substr($_,0,length($filename)-length($file_num));	
#    			print "DOLLAR_FILENAME : ",$filename,"\n"; 
    			
    			my $end = "00".$new_number;
    			$end = substr($end,length($end)-3,3);
#	  			print "DOLLAR_END : ",$end,"\n"; 
    			$target_file = $File::Find::dir."/".$filename.$end.$ext;
#   			print "TARGET_FILE : ",$target_file,"\n"; 
				if ( $target_file ne $File::Find::name ) { 
					rename ($File::Find::name, $target_file) ;
				}
				$new_number++;	
			}	 	 
		}
	}
}

sub add_digits_number_file {
	my $dir ;	
#	print "ORDER BEGIN",$_,"\n";
	if ( !($_ =~ /^\./) ) {
		if ( -d $File::Find::name ) { 
    		$dir = $File::Find::dir;
#    		print "DOLLAR_DIR",$dir,"\n";
    	}	
    	else { 
#    		print "DOLLAR_DIEZE : ",$_,"\n"; 
    		my ($filename,$_dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
    		if ($filename =~ /([0-9]+)$/) { 
    			my $file_num = $1;
    			$filename = substr($_,0,length($filename)-length($file_num));	
#    			print "DOLLAR_FILENAME : ",$filename,"\n"; 
    			
    			my $end = "0".$file_num;
    			$end = substr($end,length($end)-4,4);
#	  			print "DOLLAR_END : ",$end,"\n"; 
    			$target_file = $File::Find::dir."/".$filename.$end.$ext;
#    			print "TARGET_FILE : ",$target_file,"\n"; 
				if ( $target_file ne $File::Find::name ) { 
					rename ($File::Find::name, $target_file) ;
				}
			}	 	 
		}
	}
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

# Called by File::Find and do not backup hidden files

sub backup_file {
	if ( !($_ =~ /^\./) ) {
		if ( -d $_ ) { 
    		my @source_dirs = File::Spec->splitdir( $File::Find::name ); 		
    		shift @source_dirs;
    		shift @source_dirs;
    		unshift @source_dirs, $BACKUP_DIR;
    		unshift @source_dirs, $BACKUP_VOLUME;
    		$target_dir = File::Spec->catdir( @source_dirs );
#	   		print " TARGET_DIR : ",$target_dir,"\n";
  			my @created = mkpath($target_dir);
#			print "created $_\n" for @created;
    	}	
    	else {  
    		$target_file = $target_dir."/".$_;
#	   		print "SOURCE_FILE : ", $File::Find::name,"\tTARGET_FILE : ",$target_file,"\n";  		
    		if ( -e($target_file) ) { 
    			if ( !( my $res = ( compare($File::Find::name,$target_file) ) == 0 ) ) { 
#   				print "compare : equiv but result : ",$res,"\n"; 
    				my $source_file = increment_filename_version($File::Find::name);
#  					print "New source file : ",$source_file,"\n"; 
    				$target_file = $target_dir."/".fileparse($source_file);
#    				print "New target file : ",$target_file,"\n"; 
    				copy($File::Find::name,$source_file) or die "Copy failed: $!";
    				move($source_file,$target_file) or die "Copy failed: $!";
	   				print "Fichier : ",$_," copié sur le NAS!","\n"; 
    			}	
    			else { 
    				print "Fichier : ",$_," déjà présent sur le NAS!","\n";
    			}
    		}
    		else {
    			copy($File::Find::name,$target_file) or die "Copy failed: $!";
    			print "Fichier : ",$_," copié sur le NAS!","\n"; 
    		}  	   
		}
	}
}


# RETURN FILE_EXTENSION OF A FILE. ASSUMES FILE EXISTS
sub get_file_extension {
	my $fullname = $_[0];
	my ($file,$dir,$ext) = fileparse($fullname, qr/\.[^.]*/);
	if ($ext eq "") {
		return $ext;
	}
	else {
		return substr($ext,1);
	}
}

# ASSUMES FILE EXISTS AND ABSOLUTE FILENAME
sub compute_file_extension {
	my $file = $_[0];
	my $file_return = `file -i "$file"`;
#		print "FILE_RETURN : ",$file_return,"\n";
		if ( $file_return =~ /\/([\w]+)$/ ) {
#		print "DOLLAR_1 : ",$1,"\n";
		return $1;
	}	
}		

sub remove_only {
	if ( -f $File::Find::name ) {
		unlink($File::Find::name); 	
	}
	if ( $File::Find::name =~ /^(\/[^\/]+){6}[0-9]{4}/ ) { 
	}
	else { 
		if ( (-d $File::Find::name) && ($File::Find::name =~ /^(\/[^\/]+){6}/)) {
			rmdir($File::Find::name); 	
		}
	}
}
	
# Write metadata and rename filename
sub write_metadata {
	my $new_filename;
#	print $File::Find::name,"\n";

    if ( -f $File::Find::name ) {
#    	print "-F","\n";
		if ( is_an_image_file($File::Find::name) ) {
#			print "Image","\n";
			my ($file_name,$dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
			if ($ext eq "") {
				$ext = compute_file_extension($File::Find::name);
			}
			else {
				$ext = substr($ext,1);
			}
			my @dirs = File::Spec->splitdir( $dir );
			my $nc = "Diapo";
    		my $event = $dirs[$#dirs-1];
			my $year = $dirs[$#dirs-2];
			my $exifTool_object = new Image::ExifTool;
			my $info = $exifTool_object->ImageInfo($File::Find::name);
#			print " FILE: ", $file_name," DIR : ",$dir," EXT : ",$ext,"\n";
    		$exifTool_object->SetNewValue(Keywords);
    		$exifTool_object->SetNewValue(Keywords => [$year,$event,$nc]);
    		$exifTool_object->WriteInfo($File::Find::name);
    		$event =~ s/\s+/\_/g  ;
    		
			# build_new_filename if not match
#			print $file_name,"\n";
    		if ( $file_name =~ /([0-9]+)$/ ) {	
				$new_filename = $year."_".$event."_".$1.".".$ext;
#				print "FILE : ",$File::Find::name,"NEW_FILE : ",$new_filename ,"\n";
				if ( $new_filename ne $file_name ) {
					$new_filename = File::Spec->catfile( @dirs, $new_filename ); 
					if ( rename($File::Find::name,$new_filename) != 1 ) {
    					exit();
    				}
    			}		
    		}
    		else {
    		# NOT A MINOLTA SCAN	
    			unlink($File::Find::name); 
    		}	    		
		}
		else {
    		# NOT AN IMAGE	
    		unlink($File::Find::name); 
    	}	 
	}
}

### MAIN ###

my $id = getlogin();

my $ABS_PICTURES_STEP_1_DIR = File::Spec->catdir( "/Users", $id, $REL_PICTURES_STEP_1_DIR );
my $ABS_PICTURES_STEP_2_DIR = File::Spec->catdir( "/Users", $id, $REL_PICTURES_STEP_2_DIR );
my $ABS_PICTURES_STEP_3_DIR = File::Spec->catdir( "/Users", $id, $REL_PICTURES_STEP_3_DIR );

if (! (-e $BACKUP_VOLUME)) {
	my $res = `mkdir $BACKUP_VOLUME`;
	if ( -d $BACKUP_VOLUME ) {
		mount_volume($BACKUP_VOLUME);
	}
	else {
		print "Echec à la création de ",$BACKUP_VOLUME,"\n";	
	}
}	

if ( file_exists($BACKUP_VOLUME) ) {
	find(\&backup_file, $ABS_PICTURES_STEP_1_DIR );
	print "Phase de sauvegarde des images numérisées terminée","\n";
	find(\&write_metadata, $ABS_PICTURES_STEP_1_DIR );
	print "Phase d'écriture des métadonnées terminée","\n";
#	find(\&backup_file, $ABS_PICTURES_STEP_1_DIR );
	finddepth(\&add_digits_number_file, $ABS_PICTURES_STEP_1_DIR );
#	find(\&backup_file, $ABS_PICTURES_STEP_1_DIR );
	finddepth(\&order_and_number_file, $ABS_PICTURES_STEP_1_DIR );
#	find(\&backup_file, $ABS_PICTURES_STEP_1_DIR );
	`ditto $ABS_PICTURES_STEP_1_DIR $ABS_PICTURES_STEP_2_DIR`;
	print "Copie vers le dossier $ABS_PICTURES_STEP_2_DIR terminée","\n";
	finddepth(\&remove_only, $ABS_PICTURES_STEP_1_DIR );
	find(\&backup_file, $ABS_PICTURES_STEP_2_DIR );
	print "Phase de sauvegarde des images modifiées terminée","\n";	
	if ($nb_images != 0 ) {
		print "Succès : ",$nb_images, " images traitées","\n";
	} else {
		print "Aucune image trouvée","\n";
	} 
} else {
	print "Echec : NAS introuvable !","\n";
	exit();
}
