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
	if (defined($location->{MD5Sum})) {
		my $digest = Digest->new('MD5');
		$digest->add($data);
		# MD5 produces a byte string result
		return $digest->digest() eq $location->{MD5Sum};
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

sub TransformCallInstructions {
	my ($self, $data, $offset) = @_;
	if (length($data) < 5) {
		return $data;
	}
	if (!defined($offset)) {
		$offset = 0;
	}
	my $size = length($data) - 4;
	my $i = 0;
	while ($i < $size) {
		# Does it appear to be a CALL or JMP instruction with a relative 32-bit address?
		my $instr = ord(substr($data, $i, 1));
		if ($instr == 0xe8 || $instr == 0xe9) {
			$i++;
			# Verify that the high byte of the address is $00 or $FF. If it isn't, then what we've encountered most likely isn't a CALL or JMP.
			my $arg = ord(substr($data, $i + 3, 1));
			if ($arg == 0x00 || $arg == 0xff) {
				# Change the lower 3 bytes of the address to be relative to the beginning of the buffer, instead of to the next instruction. If decoding, do the opposite.
				my $addr = $offset + $i + 4;
				if ($i == 0x90000) {
					my $old = unpack('L', substr($data, $i, 4));
					printf("instr:0x%02x addr:0x%08x old:0x%08x ", $instr, $addr, $old);
				}
				# if (!Encode) {
					$addr = -$addr;
				# }
				# Replace address
				for (my $x = 0; $x <= 2; $x++) {
					$addr += ord(substr($data, $i + $x, 1));
					# Mask out the LSB or we might get a Unicode character...
					substr($data, $i + $x, 1) = chr($addr & 0xff);
					$addr >>= 8;
				}
				if ($i == 0x90000) {
					my $new = unpack('L', substr($data, $i, 4));
					printf("new:0x%08x\n", $new);
				}
			}
			$i += 4;
		} else {
			$i++;
		}
	}
	return $data;
}

1;

