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

# use strict;

# REC_FILES struct
#   {filename} 			: Only FILENAME without PATH
#	{extension} 		: FROM fileparse
#	{image_format}		: FROM EXIF MIMEType
#	{image_size}		: FROM EXIF ImageSize
#	{orientation}		: FROM EXIF Orientation
#	{nb_occ}			: 
#	{dir_type}			: FROM fileparse $dir[$DIM_HOME_ENV+1];
#	{path}				: $File::Find::dir;
#	{size} 				: FROM EXIF FileSize
# 	{mtime} 			: FROM stat $mtime;
#	{signature}			: md5($File::Find::name); 
#	{keywords} 			: FROM EXIF Keywords


# REC_DIRS struct
#	{dir_name} 			: FROM File::Spec->catdir( @dir );
#	{dir_level} 		: FROM $#dir;
#	{nb_files_in_dir}	: 


# REC_REPORT struct
#	{id} 			: FROM localtime
#	{proc} 			: FROM $#dir;
#	{arg}			: ARGUMENT (SALAR or ARRAY )
#	{nb_files_read}	: NB
#	{nb_files_mod}	: NB
#	{rep_status}		: Global status computed (1 if no error lines, 0 else )
#	{lines_status} 			: ARRAY OF HASHES
#		[	{inf}	: Input file
#		[	{ouf}	: Output file
#		[	{status}	: 1 for success, 0 for failure
#		[   {error}		: error if any

# REC_LINE_REPORT struct
#		{rec_line_id}		: line nb
#		{rec_line_if_file}	: Input file
#		{rec_line_of_file}	: Output file
#		{rec_line_status}	: 1 for success, 0 for failure
#		{rec_line_error}	: error if any


# WITH NAS
my $BACKUP_VOLUME 			= "/Volumes/BACKUP";
my $BACKUP_ENV_LOCATION 	= "/SAUVEGARDES/IMAGES";
my $BACKUP_ENV 				= "/TEST"; # For testing
# my $ENV 					= "MINOLTA"; # For production

my $BACKUP_HOME_ENV			= File::Spec->catdir( $BACKUP_VOLUME, $BACKUP_ENV_LOCATION, $BACKUP_ENV ); 
my @BACKUP_HOME_ENV			= File::Spec->splitdir( $BACKUP_HOME_ENV );
my $DIM_BACKUP_HOME_ENV		= $#BACKUP_HOME_ENV ; # (5)

# my $BACKUP_DIR			= File::Spec->catdir( $BACKUP_VOLUME, $BACKUP_ENV_LOCATION, $BACKUP_ENV );

# FOR LOCAL PURPOSE

my $LOCAL_VOLUME			= "/Users";
my $LOCAL_ENV_LOCATION		= "/LochNessIT/Pictures"; 
my $LOCAL_ENV 				= "/MINOLTA";

my $LOCAL_HOME_ENV			= File::Spec->catdir( $LOCAL_VOLUME, $LOCAL_ENV_LOCATION, $LOCAL_ENV ); 
my @LOCAL_HOME_ENV			= File::Spec->splitdir( $LOCAL_HOME_ENV );
my $DIM_LOCAL_HOME_ENV		= $#LOCAL_HOME_ENV ; # (5)

# my $LOCAL_DIR				= File::Spec->catdir( $LOCAL_VOLUME, $LOCAL_ENV_LOCATION, $LOCAL_ENV );






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


sub bulk_copy {
	my $dir = File::Spec->catdir( $LOCAL_HOME_ENV, $_[0] );
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$mon 	+= 1;
	$year 	+= 1900;
	$mday 	= substr("0".$mday,length("0".$mday)-2, 2);
	$mon 	= substr("0".$mon,length("0".$mon)-2, 2);
	$hour 	= substr("0".$hour,length("0".$hour)-2, 2);
	$min 	= substr("0".$min,length("0".$min)-2, 2);
	
	$report_id = join("_", $year, $mon, $mday, join("-", $hour,$min));
	
	my $proc = "BULK_COPY";
	$files_read = 0,
	$files_mod = 0;
	init_proc_report($report_id, $proc, $dir);
	
#	find(\&build_REC_FILE, $dir);

	find(\&backup_dir, $dir );
	if ( $REC_REPORT{$report_id}{rep_status} ) {
		print "Dossier ",$dir,",contenant ",$files_read," fichiers, copié sur le NAS\n";
	}
	else {
		print "Echec de la procédure ", $proc," du dossier ",$dir,". ",$files_mod," / ",$files_read," copiés \n";
	}
}	

sub init_proc_report {

	my $report_id 	= $_[0];
	my $proc		= $_[1];
	my $dir			= $_[2];

	my $rec_report;
	
	$rec_report->{id} 					= $report_id;
	$rec_report->{proc}					= $proc;
	$rec_report->{args}					= $dir;
	$rec_report->{nb_files_read} 		= 0;
	$rec_report->{nb_files_mod}			= 0;
	$rec_report->{rep_status}			= -1;
	$rec_report->{lines_status}			= [ ];
	$REC_REPORT{ $rec_report->{id} } 	= $rec_report;
	
}


# BULK COPY FROM A LIST OF GIVEN LEVEL DIRS (META, JPG, ....)
# ECRASE A LA CIBLE
sub backup_dir {
	if ( !($_ =~ /^\./) ) {
		if ( -d $_ ) { 

    	}	
    	else {  
    		$files_read++;
    		# COMPUTE TARGET FILE DIR
    		my @if_dir 	= File::Spec->splitdir( $File::Find::dir );
    		splice( @if_dir, 0, $DIM_LOCAL_HOME_ENV, @BACKUP_HOME_ENV );

	   		my $of = File::Spec->catdir( @if_dir, $_ );
	   		   		
	   		my $rec_line;
	   		$rec_line->{id}		= $files_read;
	   		$rec_line->{inf}	= $File::Find::name;
			$rec_line->{ouf}	= $of;
			
			if ( !(-e File::Spec->catdir( @if_dir )) ) {
   				mkpath(File::Spec->catdir( @if_dir ));
   			}
   			if ( !( copy($File::Find::name, $of) ) ) {
   				$rec_line->{error} 	= $!;
				$rec_line->{status} = 0;
				$REC_REPORT{$report_id}{rep_status} = 0;
			}	
			else {	
				$rec_line->{error} 	= "Fichier copié";
				$rec_line->{status} = 1;
				$files_mod++;
				
			}
			
			$REC_LINE{ $rec_line->{id} } = $rec_line;
			
			print "REC LINE FOR : ",$files_read,"\n";
#
			print "\t [ ", 
				$REC_LINE{$files_read}{inf},"\t", 
				$REC_LINE{$files_read}{ouf},"\t",	
				$REC_LINE{$files_read}{status},"\t",
				$REC_LINE{$files_read}{error}," ] \n";
			
			push @{ $REC_REPORT{$report_id}{lines_status} }, $REC_LINE{$files_read}; 
			 
	   		$REC_REPORT{$report_id}{nb_files_read}		= $files_read;
	   		$REC_REPORT{$report_id}{nb_files_mod} 		= $files_mod;
	   		$REC_REPORT{$report_id}{rep_status} 		**= 2; # RULE TO COMPUTE GLOBAL STATUS 1 FOR SUCESS
		}
	}
}



sub build_REC_FILE {
	
	if ( !($_ =~ /^\./) ) {
		if ( -d $_ ) {
			
    	}	
    	else { 
    		my @dir = File::Spec->splitdir( $File::Find::dir );
    		my ($file,$dir,$ext) 	= fileparse($File::Find::name, qr/\.[^.]*/);
    		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($File::Find::name);
    		if ( $REC_FILE{$_} ) {
    			$REC_FILE{$_}{nb_occ}++;
    			$dir[$DIM_BACKUP_HOME_ENV+1] = $TEMP_DIR;	
    			move($File::Find::name, File::Spec->catdir( @dir ));
    		}	
    		else {
    			my $exifTool_object 			= new Image::ExifTool;
    			my $rec_file;
    			
    			my $info 						= $exifTool_object->ImageInfo($File::Find::name);
    			
    			$rec_file->{filename} 			= $_;			
				$rec_file->{extension} 			= $ext;
				$rec_file->{image_format}		= $exifTool_object->GetValue('MIMEType', 'ValueConv');
				$rec_file->{file_size}			= $exifTool_object->GetValue('FileSize', 'ValueConv');
				$rec_file->{orientation}		= $exifTool_object->GetValue('Orientation', 'ValueConv');
				$rec_file->{nb_occ}				= 1; 
				$rec_file->{dir_type}			= $dir[$DIM_BACKUP_HOME_ENV+1];
				$rec_file->{path}				= $File::Find::dir;
				$rec_file->{size} 				= $exifTool_object->GetValue('ImageSize', 'ValueConv');
				$rec_file->{mtime} 				= $mtime;
				my $val 						= $exifTool_object->GetValue('Keywords', 'ValueConv');
				if (ref $val eq 'ARRAY') {
    				push @{ $rec_file->{keywords} }, join(', ', @$val);
				} 					
    			$REC_FILE{ $rec_file->{filename} } 	= $rec_file;
			}
		}	
	}
}

sub print_SIMPLE_REPORT {
	print "[ REPORT FOR : ",$report_id," ] \n";

	print 		"\t ", $REC_REPORT{$report_id}{proc},"\n", 
				"\t ", $REC_REPORT{$report_id}{args},"\n",	
				"\t ", $REC_REPORT{$report_id}{nb_files_read},"\n",
				"\t ", $REC_REPORT{$report_id}{nb_files_mod},"\n",
				"\t ", $REC_REPORT{$report_id}{rep_status},"\n";
	for my $line ( @{ $REC_REPORT{$report_id}{lines_status} } ) {
		print "\t [ ",$line->{id},"\t",$line->{inf},"\t",$line->{ouf},"\t",$line->{status},"\t",$line->{error}," ] \n";
		}	
			
}

sub print_SIMPLE_REC_LINE {
	print "REC LINE FOR : ",$files_read,"\n";

	print "( ", 
			$REC_LINE{$files_read}{inf},"\t", 
			$REC_LINE{$files_read}{ouf},"\t",	
			$REC_LINE{$files_read}{status},"\t",
			$REC_LINE{$files_read}{errro},"\n";
}

# MAIN

bulk_copy($SCAN_DIR);
print_SIMPLE_REPORT;
