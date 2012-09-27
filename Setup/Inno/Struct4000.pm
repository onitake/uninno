#!/usr/bin/perl

package Setup::Inno::Struct4000;

use strict;
use base qw(Setup::Inno::Struct2008);
use Digest;

sub CheckFile {
	my ($self, $data, $checksum) = @_;
	my $digest = Digest->new('CRC-32');
	$digest->add($data);
	# CRC-32 produces a numeric result
	return $digest->digest() == $checksum;
}

sub SetupBinaries {
	my ($self, $reader, $compression) = @_;
	my $ret = { };
	my $wzimglength = $reader->ReadLongWord();
	$ret->{WizardImage} = $reader->ReadByteArray($wzimglength);
	my $wzsimglength = $reader->ReadLongWord();
	$ret->{WizardSmallImage} = $reader->ReadByteArray($wzsimglength);
	if ($compression) {
		my $cmpimglength = $reader->ReadLongWord();
		$ret->{CompressImage} = $reader->ReadByteArray($cmpimglength);
	}
	return $ret;
}

1;

