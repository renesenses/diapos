#!/usr/local/bin/perl -w
#!/usr/bin/perl -w

# FONCTIONNE !!
# REPERTOIRE EN ECRITURE A PRECISER

use Image::Magick;
use File::Compare;
use File::Basename;
use File::Path;
use File::Spec;
use File::Copy;
use File::Find;


my $nb_images = 0;

# SUBS

sub intel_is_an_image_file {
	my $file = $_[0]; 
#	print "DOLLAR_FILE : ",$file, "COMP_EXT : ",compute_file_extension($file),"\n"; 
	if ( (get_file_extension($file) eq "tiff") || (get_file_extension($file) eq "jpeg") ) {
		$nb_images++;
		return 1;
	}
	else {
		return 0; 
	}
}

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

sub display_image {
	my $image_name = $_[0];
	my $image = Image::Magick->new;
	open(IMAGE, $image_name);
	$image->Read(file=>\*IMAGE);
	$image->Display(file=>\*IMAGE);
	close(IMAGE);
}


sub process_images {

	my $new_filename;
	my $file_name;
	my $dir;
	my $ext;
	
    if ( -f $File::Find::name ) {
		if ( intel_is_an_image_file($File::Find::name) ) {
			my ($file_name,$dir,$ext) = fileparse($File::Find::name, qr/\.[^.]*/);
			my $output_filename  = $file_name . ".jpg";
			$output_filename = File::Spec->catfile( $dir, $output_filename );  
					
			my $image = Image::Magick->new;
			
			open(INPUT_IMAGE, $File::Find::name);
  			$image->Read(file=>\*INPUT_IMAGE);
		
			my $tiff = $image->Read($File::Find::name);
			open(OUTPUT_IMAGE, ">$output_filename");
		
# TRAITEMENT REALISE : Conversion en jpg		
			my $jpg = $image->Write(file=>\*OUTPUT_IMAGE, filename=>$output_filename, magick=>'jpg');			
			close(OUTPUT_IMAGE);
			close(INPUT_IMAGE);
			
			@$tiff = ();
			@$jpg = ();
			undef $image;

    	}
    	else  {
#      		print $File::Find::name,"is not an image\n";  	 
		}
    }
    else  {
#      	print $File::Find::name,"is not a file\n";  	 
	}
}



# MAIN

my $REL_PICTURES_STEP_2_DIR = "Pictures/MINOLTA/META";
my $REL_PICTURES_STEP_3_DIR = "Pictures/MINOLTA/POST";

my $id = getlogin();

my $ABS_PICTURES_STEP_2_DIR = File::Spec->catdir( "/Users", $id, $REL_PICTURES_STEP_2_DIR );
my $ABS_PICTURES_STEP_3_DIR = File::Spec->catdir( "/Users", $id, $REL_PICTURES_STEP_3_DIR );


# `ditto $ABS_PICTURES_STEP_2_DIR $ABS_PICTURES_STEP_3_DIR`;
find(\&process_images, $ABS_PICTURES_STEP_3_DIR);

if ($nb_images != 0 ) {
	print "Succès : ",$nb_images, " images traitées","\n";
} else {
	print "Aucune image trouvée","\n";
} 
