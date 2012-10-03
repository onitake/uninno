#!/usr/bin/perl

package Setup::Inno::Struct4009;

use strict;
use base qw(Setup::Inno::Struct4001);
use IO::Uncompress::AnyInflate;
use Setup::Inno::FieldReader;

# ZlibBlockReader4107
sub FieldReader {
	my ($self, $reader) = @_;
	my $creader = IO::Uncompress::AnyInflate->new($reader, Transparent => 0) || die("Can't create zlib decompressor");
	my $freader = Setup::Inno::FieldReader->new($creader) || die("Can't create field reader");
	return $freader;
}

1;

