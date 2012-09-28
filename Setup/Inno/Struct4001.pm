#!/usr/bin/perl

package Setup::Inno::Struct4001;

use strict;
use base qw(Setup::Inno::Struct4000);
use feature 'switch';
use Fcntl;
use IO::Uncompress::AnyInflate;
use IO::Uncompress::Bunzip2;
use Setup::Inno::LzmaReader;
use constant {
	ZLIBID => "zlb\x{1a}",
};

sub ReadFile {
	my ($self, $input, $header, $location, $password) = @_;
	
	#use Data::Dumper;
	#print Dumper $location;
	
	# Note: once we support decryption, make sure the password is interpreted as UTF-16LE
	($location->{ChunkEncrypted} && !defined($password)) && die("File is encrypted, but no password was given");
	
	$input->seek($location->{StartOffset}, Fcntl::SEEK_CUR);
	$input->read(my $buffer, 4) || die("Can't read compressed block magic");
	($buffer eq ZLIBID) || die("Compressed block ID invalid");

	my $reader;
	given ($header->{CompressMethod}) {
		when ('Zip') {
			$reader = IO::Uncompress::AnyInflate->new($input, Transparent => 0) || die("Can't create zlib reader");
		}
		when ('Bzip') {
			$reader = IO::Uncompress::Bunzip2->new($input, Transparent => 0) || die("Can't create bzip2 reader");
		}
		when ('Lzma') {
			$reader = Setup::Inno::LzmaReader->new($input, $location->{ChunkCompressedSize}) || die("Can't create LZMA reader");
		}
		default {
			# Plain reader for stored mode
			$reader = $input;
		}
	}
	
	$reader->seek($location->{ChunkSuboffset}, Fcntl::SEEK_CUR);
	($reader->read($buffer, $location->{OriginalSize}) >= $location->{OriginalSize}) || die("Can't uncompress file");
	
	if ($location->{CallInstructionOptimized}) {
		# We could just transform the whole data, but this will expose a flaw in the original algorithm:
		# It doesn't detect jump instructions across block boundaries.
		# This means we need to process block by block like the original.
		# The block size is 64KB here.
		for (my $offset = 0; $offset < length($buffer); $offset += 0x10000) {
			substr($buffer, $offset, 0x10000) = $self->TransformCallInstructions(substr($buffer, $offset, 0x10000), $offset);
		}
	}
	
	($self->CheckFile($buffer, $location->{Checksum})) || die("Invalid file checksum");
	
	return $buffer;
}

1;

