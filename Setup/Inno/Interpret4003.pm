#!/usr/bin/perl

package Setup::Inno::Interpret4003;

use strict;
use base qw(Setup::Inno::Interpret4000);
use Digest;
use Win::Exe::Util;

sub OffsetTableSize {
	return 40;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L7)<', 'ID', 'TotalSize', 'OffsetEXE', 'CompressedSizeEXE', 'UncompressedSizeEXE', 'CRCEXE', 'Offset0', 'Offset1');
	return $ofstable;
}

1;

