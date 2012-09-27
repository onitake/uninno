#!/usr/bin/perl

package Setup::Inno::Struct4105;

use strict;
use base qw(Setup::Inno::Struct4009);
use Setup::Inno::BlockReader;
use Setup::Inno::LzmaReader;
use IO::File;
use Data::Hexdumper;

sub Compression1 {
	my ($self, $header) = @_;
	if (!defined($header->{CompressMethod}) || $header->{CompressMethod} eq 'Stored' || $header->{CompressMethod} eq 0) {
		return undef;
	}
	return $header->{CompressMethod};
}

sub FieldReader {
	my ($self, $reader) = @_;
	my $breader = Setup::Inno::BlockReader->new($reader, 4096) || die("Can't create block reader");
	my $creader = $breader;
	if ($breader->compressed()) {
		$creader = Setup::Inno::LzmaReader->new($breader);
	}
	my $freader = Setup::Inno::FieldReader->new($creader) || die("Can't create field reader");
	return $freader;
}

1;

