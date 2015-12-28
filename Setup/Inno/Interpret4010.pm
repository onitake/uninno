#!/usr/bin/perl

package Setup::Inno::Interpret4010;

use strict;
use base qw(Setup::Inno::Interpret4003);

sub OffsetTableSize {
	return 44;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L8)<', 'ID', 'TotalSize', 'OffsetEXE', 'CompressedSizeEXE', 'UncompressedSizeEXE', 'CRCEXE', 'Offset0', 'Offset1', 'TableCRC');
	my $digest = Digest->new('CRC-32');
	$digest->add(substr($data, 0, 40));
	($digest->digest() == $ofstable->{TableCRC}) || die("Checksum error");
	return $ofstable;
}

1;

