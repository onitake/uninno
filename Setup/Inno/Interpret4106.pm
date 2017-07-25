#!/usr/bin/perl

package Setup::Inno::Interpret4106;

use strict;
use base qw(Setup::Inno::Interpret4010);
use Fcntl;
use Encode;
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

sub VerifyPassword {
	my ($self, $setup0, $password) = @_;
	if (defined($setup0->{Header}->{Options}->{shPassword})) {
		if ($setup0->{Header}->{Options}->{shPassword}) {
			my $digest = Digest->new('MD5');
			my $hash;
			if (defined($setup0->{Header}->{PasswordHash})) {
				$hash = $setup0->{Header}->{PasswordHash};
				$digest->add('PasswordCheckHash');
				$digest->add(join('', @{$setup0->{Header}->{PasswordSalt}}));
			} else {
				$hash = $setup0->{Header}->{Password};
			}
			if ($self->{IsUnicode}) {
				$digest->add(encode('UTF-16LE', $password));
			} else {
				$digest->add($password);
			}
			return $digest->digest() eq $hash;
		} else {
			return !defined($password);
		}
	} else {
		return 1;
	}
}

1;

