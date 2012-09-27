#!/usr/bin/perl

package Setup::Inno::LzmaReader;

use strict;
use base qw(IO::File);
use File::Temp;

sub new {
	my ($class, $reader, $size) = @_;

	# Read and dissect header
	$reader->read(my $header, 5) || die("Can't read LZMA header");
	my ($lclppb, $dictsize) = unpack('(CL)<', $header);
	my $pb = int($lclppb / 45);
	my $lclp = $lclppb - $pb * 45;
	my $lp = int($lclp / 9);
	my $lc = $lclp - $lp * 9;

	# Create temporary file and consume all data the reader can give us (not always a good idea, so a maximum size argument is provided)
	# Note that automatic file removal is disabled as this can cause problems (early deletion etc.)
	my $temp = File::Temp->new(UNLINK => 0) || die("Can't create temp file");
	if (defined($size)) {
		while ($size) {
			my $length = ($size > 4096) ? 4096 : $size;
			my $rdbytes = $reader->read(my $buffer, $length);
			($rdbytes == $length) || die("Didn't get all data from stream (expected $length, got $rdbytes)");
			$size -= $rdbytes;
			$temp->write($buffer) || die("Can't write to temp file");
		}
	} else {
		while (!$reader->eof()) {
			$reader->read(my $buffer, 4096) || die("Can't read from stream");
			$temp->write($buffer) || die("Can't write to temp file");
		}
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
	unlink(*$self->{LzmaReaderTempFile}) || warn("Can't delete temporary file");
	$self->SUPER::DESTROY($@);
}

1;

