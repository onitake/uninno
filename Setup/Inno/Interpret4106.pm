#!/usr/bin/perl

package Setup::Inno::Interpret4106;

use strict;
use base qw(Setup::Inno::Interpret4010);
use Fcntl;
use Setup::Inno::BlockReader;
use Setup::Inno::FieldReader;

sub OffsetTableSize {
	return 40;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L7)<', 'ID', 'TotalSize', 'OffsetEXE', 'UncompressedSizeEXE', 'CRCEXE', 'Offset0', 'Offset1', 'TableCRC');
	my $digest = Digest->new('CRC-32');
	$digest->add(substr($data, 0, 40));
	($digest->digest() == $ofstable->{TableCRC}) || die("Checksum error");
	return $ofstable;
}

sub FieldReader {
	my ($self, $reader, $offset) = @_;
	if (defined($offset)) {
		$reader->seek($offset, Fcntl::SEEK_SET);
	}
	my $creader = Setup::Inno::BlockReader->new($reader, $offset, 4096) || die("Can't create block reader");
	my $freader = Setup::Inno::FieldReader->new($creader) || die("Can't create field reader");
	return $freader;
}

1;

