#!/usr/bin/perl

package Setup::Inno::Struct4003;

use strict;
use base qw(Setup::Inno::Struct4002);
use Digest;
use Win::Exe::Util;

=comment
  TSetupLdrOffsetTable = packed record
    ID: array[1..12] of Char;
    TotalSize,
    OffsetEXE, CompressedSizeEXE, UncompressedSizeEXE, CRCEXE,
    Offset0, Offset1: Longint;
  end;
=cut
sub OffsetTableSize {
	return 40;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L7)<', 'ID', 'TotalSize', 'OffsetEXE', 'CompressedSizeEXE', 'UncompressedSizeEXE', 'CRCEXE', 'Offset0', 'Offset1');
	return $ofstable;
}

=comment
  TSetupTypeOption = (toIsCustom);
  TSetupTypeOptions = set of TSetupTypeOption;
  TSetupTypeType = (ttUser, ttDefaultFull, ttDefaultCompact, ttDefaultCustom);
  TSetupTypeEntry = packed record
    Name, Description, Languages, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: TSetupTypeOptions;
    Typ: TSetupTypeType;
    { internally used: }
    Size: LongInt;
  end;
=cut
sub SetupTypes {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		$ret->[$i]->{Name} = $reader->ReadString();
		$ret->[$i]->{Description} = $reader->ReadString();
		$ret->[$i]->{Languages} = $reader->ReadString();
		$ret->[$i]->{Check} = $reader->ReadString();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'IsCustom' ]);
		$ret->[$i]->{Typ} = $reader->ReadEnum([ 'User', 'DefaultFull', 'DefaultCompact', 'DefaultCustom' ]);
		$ret->[$i]->{Size} = $reader->ReadInteger64();
	}
	return $ret;
}

1;

