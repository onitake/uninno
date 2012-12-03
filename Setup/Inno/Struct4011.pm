#!/usr/bin/perl

package Setup::Inno::Struct4011;

use strict;
use base qw(Setup::Inno::Struct4010);

=comment
  { TGrantPermissionEntry is stored inside string fields named 'Permissions' }
  TGrantPermissionGroup = (ggEveryone, ggAuthUsers, ggUsers);
  TGrantPermissionEntry = record
    Group: TGrantPermissionGroup;
    AccessMask: DWORD;
  end;
=cut

=comment
  TSetupDirEntry = packed record
    DirName: String;
    Components, Tasks, Languages, Check: String;
    Permissions: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (doUninsNeverUninstall, doDeleteAfterInstall,
      doUninsAlwaysUninstall);
  end;
=cut
sub SetupDirs {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = ( 'DirName', 'Components', 'Tasks', 'Languages', 'Check', 'Permissions' );
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'UninsNeverUninstall', 'DeleteAfterInstall', 'UninsAlwaysUninstall' ]);
	}
	return $ret;
}

=comment
  TSetupRegistryEntry = packed record
    Subkey, ValueName, ValueData: String;
    Components, Tasks, Languages, Check: String;
    Permissions: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    RootKey: HKEY;
    Typ: (rtNone, rtString, rtExpandString, rtDWord, rtBinary, rtMultiString);
    Options: set of (roCreateValueIfDoesntExist, roUninsDeleteValue,
      roUninsClearValue, roUninsDeleteEntireKey, roUninsDeleteEntireKeyIfEmpty,
      roPreserveStringType, roDeleteKey, roDeleteValue, roNoError,
      roDontCreateKey);
  end;
=cut
sub SetupRegistryEntries {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = ( 'Subkey', 'ValueName', 'ValueData', 'Components', 'Tasks', 'Languages', 'Check', 'Permissions' );
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{RootKey} = $reader->ReadLongWord(); # HKEY
		$ret->[$i]->{PermissionsEntry} = $reader->ReadSmallInt();
		$ret->[$i]->{Typ} = $reader->ReadEnum([ 'None', 'String', 'ExpandString', 'DWord', 'Binary', 'MultiString' ]);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'CreateValueIfDoesntExist', 'UninsDeleteValue', 'UninsClearValue', 'UninsDeleteEntireKey', 'UninsDeleteEntireKeyIfEmpty', 'PreserveStringType', 'DeleteKey', 'DeleteValue', 'NoError', 'DontCreateKey' ]);
	}
	return $ret;
}

1;

