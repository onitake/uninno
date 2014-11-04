#!/usr/bin/perl

package Setup::Inno::Interpret2008;

use strict;
use base qw(Setup::Inno::Interpret);
use Switch 'Perl6';
use Fcntl;
use Digest;
use IO::Uncompress::AnyInflate;
use IO::Uncompress::Bunzip2;
use Win::Exe::Util;

sub OffsetTableSize {
	return 44;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L8)<', 'ID', 'TotalSize', 'OffsetEXE', 'CompressedSizeEXE', 'UncompressedSizeEXE', 'AdlerEXE', 'OffsetMsg', 'Offset0', 'Offset1');
	return $ofstable;
}

sub CheckFile {
	my ($self, $data, $location) = @_;
	my $digest = Digest->new('Adler-32');
	$digest->add($data);
	return $digest->digest() eq $location->{Checksum};
}

sub Compression1 {
	my ($self, $header) = @_;
	if (!defined($header->{CompressMethod}) || $header->{CompressMethod} =~ /Stored/i || $header->{CompressMethod} eq 0) {
		return undef;
	}
	return $header->{CompressMethod};
}

sub FieldReader {
	my ($self, $reader, $offset) = @_;
	if (defined($offset)) {
		$reader->seek($offset, Fcntl::SEEK_SET);
	}
	my $creader = IO::Uncompress::AnyInflate->new($reader, Transparent => 0) || die("Can't create zlib decompressor");
	my $freader = Setup::Inno::FieldReader->new($creader) || die("Can't create field reader");
	return $freader;
}

sub ReadFile {
	my ($self, $input, $header, $location, $offset1, $password) = @_;
	
	$input->seek($offset1 + $location->{StartOffset}, Fcntl::SEEK_SET);

	my $reader;
	if ($location->{Flags}->{ChunkCompressed}) {
		given ($header->{CompressMethod}) {
			when ('Zip') {
				$reader = IO::Uncompress::AnyInflate->new($input, Transparent => 0) || die("Can't create zlib reader");
			}
			when ('Bzip') {
				$reader = IO::Uncompress::Bunzip2->new($input, Transparent => 0) || die("Can't create bzip2 reader");
			}
			default {
				# Plain reader for stored mode
				$reader = $input;
			}
		}
	} else {
		$reader = $input;
	}
	
	($reader->read(my $buffer, $location->{OriginalSize}) >= $location->{OriginalSize}) || die("Can't uncompress file");
	
	($self->CheckFile($buffer, $location)) || die("Invalid file checksum");
	
	return $buffer;
}

1;

