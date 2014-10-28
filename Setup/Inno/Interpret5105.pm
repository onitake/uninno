#!/usr/bin/perl

package Setup::Inno::Interpret5105;

use strict;
use base qw(Setup::Inno::Interpret4106);
use Digest;
use Win::Exe::Util;

sub CheckFile {
	my ($self, $data, $location) = @_;
	# TODO Some versions might carry a SHA1 hash in Checksum
	if (defined($location->{Checksum})) {
		my $digest = Digest->new('CRC-32');
		$digest->add($data);
		# CRC-32 produces a numeric result
		return $digest->digest() == $location->{Checksum};
	}
	if (defined($location->{SHA1Sum})) {
		my $digest = Digest->new('SHA-1');
		$digest->add($data);
		# SHA-1 produces a byte string result
		return $digest->digest() eq $location->{SHA1Sum};
	}
	return 1;
}

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

