#!/usr/bin/perl

package Setup::Inno::Struct4203;

use strict;
use base qw(Setup::Inno::Struct4202);

=comment
  TSetupComponentEntry = packed record
    Name, Description, Types, Languages, Check: String;
    ExtraDiskSpaceRequired: Integer64;
    Level: Integer;
    Used: Boolean;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (coFixed, coRestart, coDisableNoUninstallWarning,
      coExclusive, coDontInheritCheck);
    { internally used: }
    Size: Integer64;
  end;
=cut
sub SetupComponents {
	my ($self, $reader, $count) = @_;
	my $ret = { };
	for (my $i = 0; $i < $count; $i++) {
		my $name = $reader->ReadString();
		if (!$name) {
			# Rather use the index if the name is empty
			$name = $i;
		}
		$ret->{$name}->{Name} = $name;
		$ret->{$name}->{Description} = $reader->ReadString();
		$ret->{$name}->{Types} = $reader->ReadString();
		$ret->{$name}->{Languages} = $reader->ReadString();
		$ret->{$name}->{Check} = $reader->ReadString();
		$ret->{$name}->{ExtraDiskSpaceRequired} = $reader->ReadInteger64();
		$ret->{$name}->{Level} = $reader->ReadInteger();
		$ret->{$name}->{Used} = $reader->ReadBoolean();
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{Options} = $reader->ReadSet([ 'Fixed', 'Restart', 'DisableNoUninstallWarning', 'Exclusive', 'DontInheritCheck' ]);
		$ret->{$name}->{Size} = $reader->ReadInteger64();
	}
	return $ret;
}

=comment
  TSetupTaskEntry = packed record
    Name, Description, GroupDescription, Components, Languages, Check: String;
    Level: Integer;
    Used: Boolean;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (toExclusive, toUnchecked, toRestart, toCheckedOnce,
      toDontInheritCheck);
 end;
=cut
sub SetupTasks {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		$ret->[$i]->{Name} = $reader->ReadString();
		$ret->[$i]->{Description} = $reader->ReadString();
		$ret->[$i]->{GroupDescription} = $reader->ReadString();
		$ret->[$i]->{Components} = $reader->ReadString();
		$ret->[$i]->{Languages} = $reader->ReadString();
		$ret->[$i]->{Check} = $reader->ReadString();
		$ret->[$i]->{Level} = $reader->ReadInteger();
		$ret->[$i]->{Used} = $reader->ReadBoolean();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'Exclusive', 'Unchecked', 'Restart', 'CheckedOnce', 'DontInheritCheck' ]);
	}
	return $ret;
}

1;