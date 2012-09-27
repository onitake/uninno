#!/usr/bin/perl

package Setup::Inno::Struct4200;

use strict;
use base qw(Setup::Inno::Struct4106);
use Digest;

sub CheckFile {
	my ($self, $data, $checksum) = @_;
	my $digest = Digest->new('MD5');
	$digest->add($data);
	my $dig = $digest->digest();
	#use Data::Hexdumper;
	#print hexdump $dig;
	#print hexdump $checksum;
	return $dig eq $checksum;
}

1;

