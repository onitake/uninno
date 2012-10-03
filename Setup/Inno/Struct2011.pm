#!/usr/bin/perl

package Setup::Inno::Struct2011;

use strict;
use base qw(Setup::Inno::Struct2008);

=comment
  TSetupDirEntry = packed record
    DirName: String;
    Components, Tasks: String;
    Attribs: Integer;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (doUninsNeverUninstall, doDeleteAfterInstall,
      doUninsAlwaysUninstall);
  end;
=cut
sub SetupDirs {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		$ret->[$i]->{DirName} = $reader->ReadString();
		$ret->[$i]->{Components} = $reader->ReadString();
		$ret->[$i]->{Tasks} = $reader->ReadString();
		$ret->[$i]->{Attribs} = $reader->ReadInteger();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'UninsNeverUninstall', 'DeleteAfterInstall', 'UninsAlwaysUninstall' ]);
	}
	return $ret;
}

1;

