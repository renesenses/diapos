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


my $REL_PICTURES_STEP_1_DIR = "Pictures/MINOLTA/SCANS";

my $nb_images = 0;

### SUB ###

# With $var instead

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

	
# Write metadata and rename filename
sub add_file_image_extension {
	my $new_filename;
#	print $File::Find::name,"\n";

    if ( -f $File::Find::name ) {
#    	print "-F","\n";
		if ( is_an_image_file($File::Find::name) ) {
#			print "Image","\n";
			my ($file_name,$dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
			if ($ext eq "") {
				$nb_images++;
				$ext = compute_file_extension($File::Find::name);
				$new_filename = $File::Find::name .".".$ext;
				rename($File::Find::name,$new_filename);
#				unlink($File::Find::name);
			}
    	}	 
	}
}

### MAIN ###

my $id = getlogin();

my $ABS_PICTURES_STEP_1_DIR = File::Spec->catdir( "/Users", $id, $REL_PICTURES_STEP_1_DIR );

my $nextruntime;

while(1){
   if ( time()>=$nextruntime ) {
   		find(\&add_file_image_extension, $ABS_PICTURES_STEP_1_DIR );
		print "Extension ajoutée sur $nb_images !","\n";
      	$nextruntime=time()+150;
   }
   sleep 1;
}

