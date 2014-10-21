#!/usr/bin/perl

package Setup::Inno::Interpret5105;

use strict;
use base qw(Setup::Inno::Interpret4106);
use Digest;
use Win::Exe::Util;

sub OffsetTableSize {
	return 44;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L8)<', 'ID', 'Version', 'TotalSize', 'OffsetEXE', 'UncompressedEXE', 'CRCEXE', 'Offset0', 'Offset1', 'TableCRC');
	my $digest = Digest->new('CRC-32');
	$digest->add(substr($data, 0, 40));
	($digest->digest() == $ofstable->{TableCRC}) || die("Checksum error");
	return $ofstable;
}

1;

