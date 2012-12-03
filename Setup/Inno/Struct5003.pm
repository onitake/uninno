#!/usr/bin/perl

package Setup::Inno::Struct5003;

use strict;
use base qw(Setup::Inno::Struct5002);

=comment
  TSetupFileEntry = packed record
    SourceFilename, DestName, InstallFontName: String;
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    LocationEntry: Integer;
    Attribs: Integer;
    ExternalSize: Integer64;
    PermissionsEntry: Smallint;
    Options: set of (foConfirmOverwrite, foUninsNeverUninstall, foRestartReplace,
      foDeleteAfterInstall, foRegisterServer, foRegisterTypeLib, foSharedFile,
      foCompareTimeStamp, foFontIsntTrueType,
      foSkipIfSourceDoesntExist, foOverwriteReadOnly, foOverwriteSameVersion,
      foCustomDestName, foOnlyIfDestFileExists, foNoRegError,
      foUninsRestartDelete, foOnlyIfDoesntExist, foIgnoreVersion,
      foPromptIfOlder, foDontCopy, foUninsRemoveReadOnly
      foRecurseSubDirsExternal, foReplaceSameVersionIfContentsDiffer,
      foDontVerifyChecksum, foUninsNoSharedFilePrompt);
    FileType: (ftUserFile, ftUninstExe);
  end;
=cut
sub SetupFiles {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = ('SourceFilename', 'DestName', 'InstallFontName', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{LocationEntry} = $reader->ReadInteger();
		$ret->[$i]->{Attribs} = $reader->ReadInteger();
		$ret->[$i]->{ExternalSize} = $reader->ReadInteger64();
		$ret->[$i]->{PermissionsEntry} = $self->ReadSmallInt();
		$ret->[$i]->{Options} = $reader->ReadSet(['ConfirmOverwrite', 'UninsNeverUninstall', 'RestartReplace', 'DeleteAfterInstall', 'RegisterServer', 'RegisterTypeLib', 'SharedFile', 'CompareTimeStamp', 'FontIsntTrueType', 'SkipIfSourceDoesntExist', 'OverwriteReadOnly', 'OverwriteSameVersion', 'CustomDestName', 'OnlyIfDestFileExists', 'NoRegError', 'UninsRestartDelete', 'OnlyIfDoesntExist', 'IgnoreVersion', 'PromptIfOlder', 'DontCopy', 'UninsRemoveReadOnly', 'RecurseSubDirsExternal', 'ReplaceSameVersionIfContentsDiffer', 'DontVerifyChecksum', 'UninsNoSharedFilePrompt']);
		$ret->[$i]->{FileType} = $reader->ReadEnum(['UserFile', 'UninstExe']);
	}
	return $ret;
}

=comment
  TSetupIconCloseOnExit = (icNoSetting, icYes, icNo);
  TSetupIconEntry = packed record
    IconName, Filename, Parameters, WorkingDir, IconFilename, Comment: String;
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    IconIndex, ShowCmd: Integer;
    CloseOnExit: TSetupIconCloseOnExit;
    HotKey: Word;
    Options: set of (ioUninsNeverUninstall, ioCreateOnlyIfFileExists,
      ioUseAppPaths, ioFolderShortcut);
  end;
=cut
sub SetupIcons {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = ('IconName', 'Filename', 'Parameters', 'WorkingDir', 'IconFilename', 'Comment', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{IconIndex} = $reader->ReadInteger();
		$ret->[$i]->{ShowCmd} = $reader->ReadInteger();
		$ret->[$i]->{CloseOnExit} = $reader->ReadEnum(['NoSetting', 'Yes', 'No']);
		$ret->[$i]->{HotKey} = $reader->ReadWord();
		$ret->[$i]->{Options} = $reader->ReadSet(['UninsNeverUninstall', 'CreateOnlyIfFileExists', 'UseAppPaths', 'FolderShortcut']);
	}
	return $ret;
}

1;
