#!/usr/bin/perl -w

# THINK TO IMAGE WARNINGS BE4 
# RELEASE 4 WITH WITH SYNOLOGY NAS

# DEPENDENCIES 
#	"file" unix command

use Image::ExifTool;
use Image::Magick;
use File::Compare;
use File::Basename;
use File::Path;
use File::Spec;
use File::Copy;
use File::Find;

use strict;

# HARDWARE CONSTANTS

my $ScannerManufacturerName 	= "Minolta";
my $ScannerModel				= "Dimage Dual Scan ii";





my %REC_TAGS;

my @MINOLTA_TAGS = qw(
ExifByteOrder
FileAccessDate
PhotometricInterpretation
FileModifyDate
ImageWidth
ResolutionUnit
Compression
FileSize
BitsPerSample
SamplesPerPixel
YResolution
MIMEType
StripByteCounts
RowsPerStrip
ResourceForkSize
FileType
FileInodeChangeDate
FilePermissions
ExifToolVersion
StripOffsets
Directory
ImageHeight
FileName
Orientation
PlanarConfiguration
XResolution
ImageSize
ImageSize);

my @USER_DEFINED_TAGS = qw(
	ScannerManudactuerName
	ScannerModel);
	
#	'FilmMaker',
#	'FilmModel',
#	'CameraMaker',
#	'CameraBrand'

# WITH NAS
my $BACKUP_VOLUME 			= "/Volumes/BACKUP";
my $BACKUP_ENV_LOCATION 	= "/SAUVEGARDES/IMAGES";
my $BACKUP_ENV 				= "/TEST"; # For testing
# my $ENV 					= "MINOLTA"; # For production

my $BACKUP_HOME_ENV			= File::Spec->catdir( $BACKUP_VOLUME, $BACKUP_ENV_LOCATION, $BACKUP_ENV ); 
my @BACKUP_HOME_ENV			= File::Spec->splitdir( $BACKUP_HOME_ENV );
my $DIM_BACKUP_HOME_ENV		= $#BACKUP_HOME_ENV ; # (5)

# FOR LOCAL PURPOSE

my $LOCAL_VOLUME			= "/Users";
my $LOCAL_ENV_LOCATION		= "/LochNessIT/Pictures"; 
my $LOCAL_ENV 				= "/MINOLTA";

my $LOCAL_HOME_ENV			= File::Spec->catdir( $LOCAL_VOLUME, $LOCAL_ENV_LOCATION, $LOCAL_ENV ); 
my @LOCAL_HOME_ENV			= File::Spec->splitdir( $LOCAL_HOME_ENV );
my $DIM_LOCAL_HOME_ENV		= $#LOCAL_HOME_ENV ; # (5)


# LEVELS DIR LIST
my $SCAN_DIR 				= "SCANS";
my $TEMP_DIR 				= "TEMP";
my $POST_DIR 				= "POST";
my $META_DIR 				= "META";
my $JPG_DIR 				= "JPG";
my $ERROR_DIR				= "ERROR";
my $TRASH_DIR				= "TRASH";



my %REC_DIR;
my %REC_FILE;
my %REC_REPORT;
my %REC_LINE;

my $files_read;
my $files_mod;
my $report_id;


# BEFORE ANY PROC : BUILD LIST OF IMAGES FILES
sub build_REC_FILE {
		
	if ( !($_ =~ /^\./) ) {
		if ( -d $_ ) {
			
    	}	
    	else { 
    		my @dir 				= File::Spec->splitdir( $File::Find::dir );
    		my ($file,$dir,$ext) 	= fileparse($File::Find::name, qr/\.[^.]*/);    		
    		my $exifTool_object 	= new Image::ExifTool;
    			
    		my $rec_file;
    		my $info 				= $exifTool_object->ImageInfo($File::Find::name);
    		my $MimeType 			= $exifTool_object->GetValue('MIMEType', 'ValueConv');
	
			# CHECK FILE FORMAT
			# IF IMAGE
			if ( (defined $MimeType) && ($MimeType =~ /^(image)\/([^\/]+)/ ) ) {
			
				# USER DEFINED EXIF TAGS

				$rec_file->{id} = $File::Find::name;
				$rec_file->{image_format} = $2;
				# PERSO FILE TAGS
    			$rec_file->{dir_type}		= $dir[$DIM_BACKUP_HOME_ENV+1];
    			$rec_file->{extension}		= $ext;
    			
    			# EXIF IMAGE_FILE TAGS
    			foreach my $tag (keys %$info) {
    				my $val = $$info{$tag};
    				if (defined $val) {
    					if (ref $val eq 'ARRAY') {
    						push @{ $rec_file->{$tag} }, @$val;
    					}
    					elsif (ref $val eq 'SCALAR') {
      						$val = '(Binary data)';
						}
    					$rec_file->{$tag} = $val;			
					}
				}					
    			$REC_FILE{ $rec_file->{id} } = $rec_file;
			}
		}	
	}
}



sub print_REC_FILE {
	foreach my $file (keys %REC_FILE) {
    	print $file, "\n";
    	foreach my $tag (keys %{ $REC_FILE{$file} }) {
	    	my $val = $REC_FILE{$file}{$tag};
    		if (defined $val) {
    			if (ref $val eq 'ARRAY') {
    				$val = join(" ,", @$val);
    			}
    			elsif (ref $val eq 'SCALAR') {
      				$val = '(Binary data)';
				}
			}	
		printf("\t %-30s : %s\n", $tag, $val);	
		}
    }
}

# MAIN

find(\&build_REC_FILE, $LOCAL_HOME_ENV );
print_REC_FILE;
