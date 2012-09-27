#!/usr/bin/perl

package Setup::Inno::Struct5105;

use strict;
use base qw(Setup::Inno::Struct4200);
use Digest;
use Win::Exe::Util;

sub CheckCrc {
	my ($self, $header, $crc) = @_;
	my $digest = Digest->new('CRC-32');
	$digest->add(substr($header, 0, 40));
	return $digest->digest() == $crc;
}

sub OffsetTableSize {
	return 44;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L8)<', 'ID', 'Version', 'TotalSize', 'OffsetEXE', 'UncompressedEXE', 'CRCEXE', 'Offset0', 'Offset1', 'TableCRC');
	$self->CheckCrc($data, $ofstable->{TableCRC}) || die("Checksum error");
	return $ofstable;

}

1;

