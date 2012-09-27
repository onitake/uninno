#!/usr/bin/perl

package Setup::Inno::LzmaReader;

use strict;
use base qw(IO::File);
use File::Temp;

sub new {
	my ($class, $reader) = @_;

	# Read and dissect header
	$reader->read(my $header, 5) || die("Can't read LZMA header");
	my ($lclppb, $dictsize) = unpack('(CL)<', $header);
	my $pb = int($lclppb / 45);
	my $lclp = $lclppb - $pb * 45;
	my $lp = int($lclp / 9);
	my $lc = $lclp - $lp * 9;

	# Create temporary file and consume all data the reader can give us (not always a good idea)
	# Note that automatic file removal is disabled as this can cause problems (early deletion etc.)
	my $temp = File::Temp->new(UNLINK => 0) || die("Can't create temp file");
	while (!$reader->eof()) {
		$reader->read(my $buffer, 4096) || die("Can't read from stream");
		$temp->write($buffer) || die("Can't write to temp file");
	}
	my $tempfile = $temp->filename();
	#$temp->close();
	
	# Spawn subprocess for decompression
	my $self = $class->SUPER::new("lzma --stdout --decompress --format=raw --lzma1=lc=$lc,lp=$lp,pb=$pb,dict=$dictsize $tempfile |") || die("Can't open decompressor");

	# Store temp file name, this should work on IO::Handle type objects
	*$self->{LzmaReaderTempFile} = $tempfile;

	# Rebless file handle so we can override methods
	return bless($self, $class);
}

# And all this hackery so we can make sure the temp file gets destroyed at the right time...
sub DESTROY {
	my $self = shift;
	unlink(*$self->{LzmaReaderTempFile});
	$self->SUPER::DESTROY($@);
}

1;

