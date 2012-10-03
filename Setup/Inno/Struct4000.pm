#!/usr/bin/perl

package Setup::Inno::Struct4000;

use strict;
use base qw(Setup::Inno::Struct3007);
use Digest;

sub CheckFile {
	my ($self, $data, $checksum) = @_;
	my $digest = Digest->new('CRC-32');
	$digest->add($data);
	# CRC-32 produces a numeric result
	return $digest->digest() == $checksum;
}

sub SetupBinaries {
	my ($self, $reader, $compression) = @_;
	my $ret = { };
	my $wzimglength = $reader->ReadLongWord();
	$ret->{WizardImage} = $reader->ReadByteArray($wzimglength);
	my $wzsimglength = $reader->ReadLongWord();
	$ret->{WizardSmallImage} = $reader->ReadByteArray($wzsimglength);
	if ($compression && $compression ne 'Lzma') {
		my $cmpimglength = $reader->ReadLongWord();
		$ret->{CompressImage} = $reader->ReadByteArray($cmpimglength);
	}
	return $ret;
}

=comment
  TSetupVersionDataVersion = packed record
    Build: Word;
    Minor, Major: Byte;
  end;
  TSetupHeaderOption = (shDisableStartupPrompt, shUninstallable, shCreateAppDir,
    shDisableDirPage, shDisableProgramGroupPage,
    shAllowNoIcons, shAlwaysRestart, shAlwaysUsePersonalGroup,
    shWindowVisible, shWindowShowCaption, shWindowResizable,
    shWindowStartMaximized, shEnableDirDoesntExistWarning,
    shDisableAppendDir, shPassword, shAllowRootDirectory, shDisableFinishedPage,
    shChangesAssociations, shCreateUninstallRegKey, shUsePreviousAppDir,
    shBackColorHorizontal, shUsePreviousGroup, shUpdateUninstallLogAppName,
    shUsePreviousSetupType, shDisableReadyMemo, shAlwaysShowComponentsList,
    shFlatComponentsList, shShowComponentSizes, shUsePreviousTasks,
    shDisableReadyPage, shAlwaysShowDirOnReadyPage, shAlwaysShowGroupOnReadyPage,
    shBzipUsed, shAllowUNCPath, shUserInfoPage, shUsePreviousUserInfo
    shUninstallRestartComputer, shRestartIfNeededByRun, shShowTasksTreeLines,
    shShowLanguageDialog);
  TSetupHeader = packed record
    AppName, AppVerName, AppId, AppCopyright, AppPublisher, AppPublisherURL,
      AppSupportURL, AppUpdatesURL, AppVersion, DefaultDirName,
      DefaultGroupName, BaseFilename, LicenseText,
      InfoBeforeText, InfoAfterText, UninstallFilesDir, UninstallDisplayName,
      UninstallDisplayIcon, AppMutex, DefaultUserInfoName,
      DefaultUserInfoOrg, DefaultUserInfoSerial, CompiledCodeText: String;
    LeadBytes: set of Char; 
    NumLanguageEntries, NumTypeEntries, NumComponentEntries, NumTaskEntries,
      NumDirEntries, NumFileEntries, NumFileLocationEntries, NumIconEntries,
      NumIniEntries, NumRegistryEntries, NumInstallDeleteEntries,
      NumUninstallDeleteEntries, NumRunEntries, NumUninstallRunEntries: Integer;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    BackColor, BackColor2, WizardImageBackColor: Longint;
    WizardSmallImageBackColor: Longint;
    Password: Longint;
    ExtraDiskSpaceRequired: Integer64;
    SlicesPerDisk: Integer;
    InstallMode: (imNormal, imSilent, imVerySilent);
    UninstallLogMode: (lmAppend, lmNew, lmOverwrite);
    UninstallStyle: (usClassic, usModern);
    DirExistsWarning: (ddAuto, ddNo, ddYes);
    PrivilegesRequired: (prNone, prPowerUser, prAdmin);
    Options: set of TSetupHeaderOption;
  end;
=cut
sub SetupHeader {
	my ($self, $reader) = @_;
	my $ret = { };
	my @strings = ('AppName', 'AppVerName', 'AppId', 'AppCopyright', 'AppPublisher', 'AppPublisherURL', 'AppSupportURL', 'AppUpdatesURL', 'AppVersion', 'DefaultDirName', 'DefaultGroupName', 'BaseFilename', 'LicenseText', 'InfoBeforeText', 'InfoAfterText', 'UninstallFilesDir', 'UninstallDisplayName', 'UninstallDisplayIcon', 'AppMutex', 'DefaultUserInfoName', 'DefaultUserInfoOrg', 'DefaultUserInfoSerial', 'CompiledCodeText');
	for my $string (@strings) {
		$ret->{$string} = $reader->ReadString();
	}
	$ret->{LeadBytes} = $reader->ReadSet(256);
	my @integers = ('NumLanguageEntries', 'NumTypeEntries', 'NumComponentEntries', 'NumTaskEntries', 'NumDirEntries', 'NumFileEntries', 'NumFileLocationEntries', 'NumIconEntries', 'NumIniEntries', 'NumRegistryEntries', 'NumInstallDeleteEntries', 'NumUninstallDeleteEntries', 'NumRunEntries', 'NumUninstallRunEntries');
	for my $integer (@integers) {
		$ret->{$integer} = $reader->ReadInteger();
	}
	$ret->{MinVersion} = $self->ReadVersion($reader);
	$ret->{OnlyBelowVersion} = $self->ReadVersion($reader);
	$ret->{BackColor} = $reader->ReadLongInt();
	$ret->{BackColor2} = $reader->ReadLongInt();
	$ret->{WizardImageBackColor} = $reader->ReadLongInt();
	$ret->{WizardSmallImageBackColor} = $reader->ReadLongInt();
	$ret->{Password} = $reader->ReadLongInt();
	$ret->{ExtraDiskSpaceRequired} = $reader->ReadInteger64();
	$ret->{SlicesPerDisk} = $reader->ReadInteger();
	$ret->{InstallMode} = $reader->ReadEnum([ 'Normal', 'Silent', 'VerySilent' ]);
	$ret->{UninstallLogMode} = $reader->ReadEnum([ 'Append', 'New', 'Overwrite' ]);
	$ret->{UninstallStyle} = $reader->ReadEnum([ 'Classic', 'Modern' ]);
	$ret->{DirExistsWarning} = $reader->ReadEnum([ 'Auto', 'No', 'Yes' ]);
	$ret->{PrivilegesRequired} = $reader->ReadEnum([ 'None', 'PowerUser', 'Admin' ]);
	$ret->{Options} = $reader->ReadSet([ 'DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'DisableAppendDir', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage', 'BzipUsed', 'AllowUNCPath', 'UserInfoPage', 'UsePreviousUserInfo', 'UninstallRestartComputer', 'RestartIfNeededByRun', 'ShowTasksTreeLines', 'ShowLanguageDialog' ]);
	# Unsupported data blocks
	$ret->{NumCustomMessageEntries} = 0;
	$ret->{NumPermissionEntries} = 0;
	# Transfer from flags
	if ($ret->{Options}->{BzipUsed}) {
		$ret->{CompressMethod} = 'Bzip';
	} else {
		# TODO: Use zlib or no compression?
		$ret->{CompressMethod} = 'Zip';
	}
	return $ret;
}

=comment
  TSetupLanguageEntry = packed record
    { Note: LanguageName is probably Unicode (test!) }
    Name, LanguageName, DialogFontName, TitleFontName, WelcomeFontName,
      CopyrightFontName, Data: String;
    LanguageID: Cardinal;
    DialogFontSize, DialogFontStandardHeight: Integer;
    TitleFontSize: Integer;
    WelcomeFontSize: Integer;
    CopyrightFontSize: Integer;
  end;
=cut
sub SetupLanguages {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = ('Name, LanguageName', 'DialogFontName', 'TitleFontName', 'WelcomeFontName', 'CopyrightFontName', 'Data');
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		# This is probably a wide string, but encoded as a regular one (length = number of bytes, not characters)
		#$ret->[$i]->{LanguageName} = decode('UTF-16LE', $ret->[$i]->{LanguageName});
		$ret->[$i]->{LanguageID} = $reader->ReadCardinal();
		$ret->[$i]->{DialogFontSize} = $reader->ReadInteger();
		$ret->[$i]->{DialogFontStandardHeight} = $reader->ReadInteger();
		$ret->[$i]->{TitleFontSize} = $reader->ReadInteger();
		$ret->[$i]->{WelcomeFontSize} = $reader->ReadInteger();
		$ret->[$i]->{CopyrightFontSize} = $reader->ReadInteger();
	}
	return $ret;
}

=comment
  TSetupTypeOption = (toIsCustom);
  TSetupTypeOptions = set of TSetupTypeOption;
  TSetupTypeEntry = packed record
    Name, Description, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: TSetupTypeOptions;
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
		$ret->[$i]->{Check} = $reader->ReadString();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'IsCustom' ]);
		$ret->[$i]->{Size} = $reader->ReadInteger64();
	}
	return $ret;
}

=comment
  TSetupComponentEntry = packed record
    Name, Description, Types, Check: String;
    ExtraDiskSpaceRequired: Integer64;
    Level: Integer;
    Used: Boolean;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (coFixed, coRestart, coDisableNoUninstallWarning, coExclusive);
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
		$ret->{$name}->{Check} = $reader->ReadString();
		$ret->{$name}->{ExtraDiskSpaceRequired} = $reader->ReadInteger64();
		$ret->{$name}->{Level} = $reader->ReadInteger();
		$ret->{$name}->{Used} = $reader->ReadBoolean();
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{Options} = $reader->ReadSet([ 'Fixed', 'Restart', 'DisableNoUninstallWarning', 'Exclusive' ]);
		$ret->{$name}->{Size} = $reader->ReadInteger64();
	}
	return $ret;
}

=comment
  TSetupTaskEntry = packed record
    Name, Description, GroupDescription, Components, Check: String;
    Level: Integer;
    Used: Boolean;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (toExclusive, toUnchecked, toRestart, toCheckedOnce);
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
		$ret->[$i]->{Check} = $reader->ReadString();
		$ret->[$i]->{Level} = $reader->ReadInteger();
		$ret->[$i]->{Used} = $reader->ReadBoolean();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'Exclusive', 'Unchecked', 'Restart', 'CheckedOnce' ]);
	}
	return $ret;
}

=comment
  TSetupDirEntry = packed record
    DirName: String;
    Components, Tasks, Check: String;
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
		$ret->[$i]->{Check} = $reader->ReadString();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'UninsNeverUninstall', 'DeleteAfterInstall', 'UninsAlwaysUninstall' ]);
	}
	return $ret;
}

=comment
  TSetupFileEntry = packed record
    SourceFilename, DestName, InstallFontName: String;
    Components, Tasks, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    LocationEntry: Integer;
    Attribs: Integer;
    ExternalSize: Integer64;
    Options: set of (foConfirmOverwrite, foUninsNeverUninstall, foRestartReplace,
      foDeleteAfterInstall, foRegisterServer, foRegisterTypeLib, foSharedFile,
      foCompareTimeStamp, foFontIsntTrueType,
      foSkipIfSourceDoesntExist, foOverwriteReadOnly, foOverwriteSameVersion,
      foCustomDestName, foOnlyIfDestFileExists, foNoRegError,
      foUninsRestartDelete, foOnlyIfDoesntExist, foIgnoreVersion,
      foPromptIfOlder, foDontCopy);
    FileType: (ftUserFile, ftUninstExe, ftRegSvrExe);
  end;
=cut
sub SetupFiles {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"SourceFilename DestName InstallFontName Components Tasks Check";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{LocationEntry} = $reader->ReadInteger();
		$ret->[$i]->{Attribs} = $reader->ReadInteger();
		$ret->[$i]->{ExternalSize} = $reader->ReadInteger64();
		$ret->[$i]->{CopyMode} = $reader->ReadEnum([ 'Normal', 'IfDoesntExist', 'AlwaysOverwrite', 'AlwaysSkipIfSameOrOlder' ]);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'ConfirmOverwrite', 'UninsNeverUninstall', 'RestartReplace', 'DeleteAfterInstall', 'RegisterServer', 'RegisterTypeLib', 'SharedFile', 'CompareTimeStamp', 'FontIsntTrueType', 'SkipIfSourceDoesntExist', 'OverwriteReadOnly', 'OverwriteSameVersion', 'CustomDestName', 'OnlyIfDestFileExists', 'NoRegError', 'UninsRestartDelete', 'OnlyIfDoesntExist', 'IgnoreVersion', 'PromptIfOlder', 'DontCopy' ]);
		$ret->[$i]->{FileType} = $reader->ReadEnum([ 'UserFile', 'UninstExe', 'RegSvrExe' ]);
	}
	return $ret;
}

=comment
  TSetupFileLocationEntry = packed record
    FirstSlice, LastSlice: Integer;
    StartOffset: Longint;
    OriginalSize, CompressedSize: Integer64;
    Adler: Longint;
    Date: TFileTime;
    FileVersionMS, FileVersionLS: DWORD;
    Flags: set of (foVersionInfoValid, foVersionInfoNotValid, foBzipped);
  end;
=cut
sub SetupFileLocations {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		$ret->[$i]->{FirstSlice} = $reader->ReadInteger();
		$ret->[$i]->{LastSlice} = $reader->ReadInteger();
		$ret->[$i]->{StartOffset} = $reader->ReadLongInt();
		$ret->[$i]->{OriginalSize} = $reader->ReadInteger64();
		$ret->[$i]->{ChunkCompressedSize} = $reader->ReadInteger64();
		$ret->[$i]->{Checksum} = $reader->ReadLongInt();
		$ret->[$i]->{TimeStamp} = $self->ReadFileTime($reader);
		$ret->[$i]->{FileVersionMS} = $reader->ReadLongWord();
		$ret->[$i]->{FileVersionLS} = $reader->ReadLongWord();
		$ret->[$i]->{Flags} = $reader->ReadSet([ 'VersionInfoValid', 'VersionInfoNotValid', 'ChunkCompressed' ]);
	}
	return $ret;
}

=comment
  TSetupIconCloseOnExit = (icNoSetting, icYes, icNo);
  TSetupIconEntry = packed record
    IconName, Filename, Parameters, WorkingDir, IconFilename, Comment: String;
    Components, Tasks, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    IconIndex, ShowCmd: Integer;
    CloseOnExit: TSetupIconCloseOnExit;
    HotKey: Word;
    Options: set of (ioUninsNeverUninstall, ioCreateOnlyIfFileExists,
      ioUseAppPaths);
  end;
=cut
sub SetupIcons {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"IconName Filename Parameters WorkingDir IconFilename Comment Components Tasks Check";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{IconIndex} = $reader->ReadInteger();
		$ret->[$i]->{ShowCmd} = $reader->ReadInteger();
		$ret->[$i]->{CloseOnExit} = $reader->ReadEnum([ 'NoSetting', 'Yes', 'No' ]);
		$ret->[$i]->{HotKey} = $reader->ReadWord();
		$ret->[$i]->{Options} = $reader->ReadSet([ 'UninsNeverUninstall', 'CreateOnlyIfFileExists', 'UseAppPaths' ]);
	}
	return $ret;
}

=comment
  TSetupIniEntry = packed record
    Filename, Section, Entry, Value: String;
    Components, Tasks, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (ioCreateKeyIfDoesntExist, ioUninsDeleteEntry,
      ioUninsDeleteEntireSection, ioUninsDeleteSectionIfEmpty,
      { internally used: }
      ioHasValue);
  end;
=cut
sub SetupIniEntries {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"Filename Section Entry Value Components Tasks Check";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'CreateKeyIfDoesntExist', 'UninsDeleteEntry', 'UninsDeleteEntireSection', 'UninsDeleteSectionIfEmpty', 'HasValue' ]);
	}
	return $ret;
}

=comment
  TSetupRegistryEntry = packed record
    Subkey, ValueName, ValueData: String;
    Components, Tasks, Check: String;
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
		my @strings = qw"Subkey ValueName ValueData Components Tasks Check";
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

=comment
  TSetupDeleteType = (dfFiles, dfFilesAndOrSubdirs, dfDirIfEmpty);
  TSetupDeleteEntry = packed record
    Name: String;
    Components, Tasks, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    DeleteType: TSetupDeleteType;
  end;
=cut
sub SetupDelete {
	my ($self, $reader, $count) = @_;
	my $ret = { };
	for (my $i = 0; $i < $count; $i++) {
		my $name = $reader->ReadString();
		if (!$name) {
			# Rather use the index if the name is empty
			$name = $i;
		}
		$ret->{$name}->{Name} = $name;
		$ret->{$name}->{Components} = $reader->ReadString();
		$ret->{$name}->{Tasks} = $reader->ReadString();
		$ret->{$name}->{Check} = $reader->ReadString();
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{DeleteType} = $reader->ReadEnum([ 'Files', 'FilesAndOrSubdirs', 'DirIfEmpty' ]);
	}
	return $ret;
}

=comment
  TSetupRunEntry = packed record
    Name, Parameters, WorkingDir, RunOnceId, StatusMsg: String;
    Description, Components, Tasks, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    ShowCmd: Integer;
    Wait: (rwWaitUntilTerminated, rwNoWait, rwWaitUntilIdle);
    Options: set of (roShellExec, roSkipIfDoesntExist,
      roPostInstall, roUnchecked, roSkipIfSilent, roSkipIfNotSilent,
      roHideWizard);
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
		my @strings = qw"Parameters WorkingDir RunOnceId StatusMsg Description Components Tasks Check";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{ShowCmd} = $reader->ReadInteger();
		$ret->{$name}->{Wait} = $reader->ReadEnum([ 'WaitUntilTerminated', 'NoWait', 'WaitUntilIdle' ]);
		$ret->{$name}->{Options} = $reader->ReadSet([ 'ShellExec', 'SkipIfDoesntExist', 'PostInstall', 'Unchecked', 'SkipIfSilent', 'SkipIfNotSilent', 'HideWizard' ]);
	}
	return $ret;
}

1;

