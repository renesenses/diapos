#!/usr/bin/perl -w

use Image::ExifTool;


	my $file = $ARGV[0];
	my $exifTool_object = new Image::ExifTool;
	my $info = $exifTool_object->ImageInfo($file);
	my $tag = 'MIMEType';
	my $val = $exifTool_object->GetValue($tag, 'ValueConv');
	
	if ( (defined $val) && ($val =~ /^(image)\/([^\/]+)/) ) {
		print $2,"\n";
	}	
	else {
		print 0,"\n";
	}

