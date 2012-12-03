#!/usr/bin/perl

package Setup::Inno::Struct5110;

use strict;
use base qw(Setup::Inno::Struct5107);

=comment
  TSetupRunEntry = packed record
    Name, Parameters, WorkingDir, RunOnceId, StatusMsg: String;
    Description, Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    ShowCmd: Integer;
    Wait: (rwWaitUntilTerminated, rwNoWait, rwWaitUntilIdle);
    Options: set of (roShellExec, roSkipIfDoesntExist,
      roPostInstall, roUnchecked, roSkipIfSilent, roSkipIfNotSilent,
      roHideWizard, roRun32Bit, roRun64Bit);
  end;
=cut
sub SetupRun {
	my ($self, $reader, $count) = @_;
	my $ret = { };
	for (my $i = 0; $i < $count; $i++) {
		my $name = $reader->ReadString();
		if (!$name) {
			# Rather use the index if the name is empty
			$name = $i;
		}
		$ret->{$name}->{Name} = $name;
		my @strings = ('Parameters', 'WorkingDir', 'RunOnceId', 'StatusMsg', 'Description', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->{$name}->{$string} = $reader->ReadString();
		}
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{ShowCmd} = $reader->ReadInteger();
		$ret->{$name}->{Wait} = $reader->ReadEnum(['WaitUntilTerminated', 'NoWait', 'WaitUntilIdle']);
		$ret->{$name}->{Options} = $reader->ReadSet(['ShellExec', 'SkipIfDoesntExist', 'PostInstall', 'Unchecked', 'SkipIfSilent', 'SkipIfNotSilent', 'HideWizard', 'Run32Bit', 'Run64Bit']);
	}
	return $ret;
}

1;
