#!/usr/bin/perl

package Win::Exe::DosHeader;

use strict;
use Win::Exe::Util;

our $ExeMagic = 0x5A4D; # 'MZ'

sub new {
	my ($class, $exe) = @_;
	my $buffer;
	$exe->{Input}->seek(0, 0);
	$exe->{Input}->read($buffer, 64);
	my $self = unpackbinary($buffer, '(S14a8S2a20l)<', 'Magic', 'Cblp', 'Cp', 'Crlc', 'Cparhdr', 'Minalloc', 'Maxalloc', 'Ss', 'Sp', 'Csum', 'Ip', 'Cs', 'Lfarlc', 'Ovno', 'Res', 'Oemid', 'Oeminfo', 'Res2', 'Lfanew');
	($self->{Magic} == $ExeMagic) || die("Invalid magic, this is not an EXE file");
	return bless($self, $class);
}

sub Describe {
	my $self = shift;
	my $prefix = (@_ > 0) ? $_[0] : '';
	my $ret = "${prefix}DOS header:\n";
	$prefix .= "  ";
	$ret .= sprintf("${prefix}Magic: '%c%c'\n", $self->{Magic} & 0xff, $self->{Magic} >> 8);
	$ret .= sprintf("${prefix}EXE size: %u bytes (%u bytes in file)\n", $self->{Cp} * 512, $self->{Cp} * 512 - $self->{Cblp});
	$ret .= sprintf("${prefix}Relocations: %u @ 0x%04x\n", $self->{Crlc}, $self->{Lfarlc});
	$ret .= sprintf("${prefix}Header size: %u bytes\n", $self->{Cparhdr} * 16);
	$ret .= sprintf("${prefix}Minimum/maximum allocation: %u / %u bytes\n", $self->{Minalloc} * 16, $self->{Maxalloc} * 16);
	$ret .= sprintf("${prefix}SS:SP: %04x:%04x\n", $self->{Ss}, $self->{Sp});
	$ret .= sprintf("${prefix}CS:IP: %04x:%04x\n", $self->{Cs}, $self->{Ip});
	$ret .= sprintf("${prefix}Checksum: 0x%04x\n", $self->{Csum});
	$ret .= sprintf("${prefix}Overlay: #%u\n", $self->{Ovno});
	$ret .= sprintf("${prefix}OEM ID/info: 0x%04x / 0x%04x\n", $self->{Oemid}, $self->{Oeminfo});
	$ret .= sprintf("${prefix}PE header: 0x%08x\n", $self->{Lfanew});
	return $ret;
}

1;

