#!/usr/bin/perl

package Win::Exe::Util;

use strict;
use DateTime;
use Exporter 'import';
our @EXPORT = qw(unpackbinary coffdate);

# Unpack a binary data structure into a hashref
sub unpackbinary {
	my ($buffer, $format, @keys) = @_;
	my @data = unpack($format, $buffer);
	my %ret;
	for (my $i = 0; $i < @data; $i++) {
		$ret{$keys[$i]} = $data[$i];
	}
	return \%ret;
}

# Convert a COFF timestamp to a DateTime object
sub coffdate {
	my ($stamp) = @_;
	return DateTime->new(year => 1970, month => 1, day => 1, hour => 0, minute => 0, second => 0)->add(seconds => $stamp);
}

1;

