#!/usr/bin/perl

package Setup::Inno::Struct;

use strict;
use base 'Setup::Inno::FieldReader';

# Override this method if your class name does not follow the usual scheme
sub Version {
	my ($self) = @_;
	if (ref($self) =~ /^Setup::Inno::Struct([0-9]{4}u?)$/) {
		return $1;
	}
	return '0000';
}

# Readers for various builtin types
sub TFileTime {
	my ($self) = @_;
	my $tlow = $self->ReadLongWord();
	my $thigh = $self->ReadLongWord();
	my $hnsecs = $tlow | ($thigh << 32);
	my $secs = int($hnsecs / 10000000);
	my $nsecs = ($hnsecs - $secs * 10000000) * 100;
	return DateTime->new(year => 1601, month => 1, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0)->add(seconds => $secs, nanoseconds => $nsecs);
}

sub HKEY {
	return shift->ReadLongWord();
}

sub DWORD {
	return shift->ReadLongWord();
}

sub TSHA1Digest {
	return shift->ReadByteArray(20);
}

sub TMD5Digest {
	return shift->ReadByteArray(16);
}

1;

