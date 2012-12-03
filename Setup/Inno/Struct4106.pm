#!/usr/bin/perl

package Setup::Inno::Struct4106;

use strict;
use base qw(Setup::Inno::Struct4105);

=comment
  TSetupLdrOffsetTable = packed record
    ID: array[1..12] of Char;
    TotalSize,
    OffsetEXE, UncompressedSizeEXE, CRCEXE,
    Offset0, Offset1: Longint;
    TableCRC: Longint;  { CRC of all prior fields in this record }
  end;
=cut
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

1;

