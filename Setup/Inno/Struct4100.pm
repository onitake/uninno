#!/usr/bin/perl

package Setup::Inno::Struct4100;

use strict;
use base qw(Setup::Inno::Struct4011);

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
    shAllowCancelDuringInstall);
  TSetupHeader = packed record
    AppName, AppVerName, AppId, AppCopyright, AppPublisher, AppPublisherURL,
      AppSupportURL, AppUpdatesURL, AppVersion, DefaultDirName,
      DefaultGroupName, BaseFilename, LicenseText,
      InfoBeforeText, InfoAfterText, UninstallFilesDir, UninstallDisplayName,
      UninstallDisplayIcon, AppMutex, DefaultUserInfoName,
      DefaultUserInfoOrg, DefaultUserInfoSerial, CompiledCodeText: String;
    LeadBytes: set of Char; 
    NumLanguageEntries, NumPermissionEntries, NumTypeEntries,
      NumComponentEntries, NumTaskEntries, NumDirEntries, NumFileEntries,
      NumFileLocationEntries, NumIconEntries, NumIniEntries,
      NumRegistryEntries, NumInstallDeleteEntries, NumUninstallDeleteEntries,
      NumRunEntries, NumUninstallRunEntries: Integer;
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
    ShowLanguageDialog: (slYes, slNo, slAuto);
    LanguageDetectionMethod: (ldUILanguage, ldLocale, ldNone);
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
	my @integers = ('NumLanguageEntries', 'NumPermissionEntries', 'NumTypeEntries', 'NumComponentEntries', 'NumTaskEntries', 'NumDirEntries', 'NumFileEntries', 'NumFileLocationEntries', 'NumIconEntries', 'NumIniEntries', 'NumRegistryEntries', 'NumInstallDeleteEntries', 'NumUninstallDeleteEntries', 'NumRunEntries', 'NumUninstallRunEntries');
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
	$ret->{InstallMode} = $reader->ReadEnum(['Normal', 'Silent', 'VerySilent']);
	$ret->{UninstallLogMode} = $reader->ReadEnum(['Append', 'New', 'Overwrite']);
	$ret->{UninstallStyle} = $reader->ReadEnum(['Classic', 'Modern']);
	$ret->{DirExistsWarning} = $reader->ReadEnum(['Auto', 'No', 'Yes']);
	$ret->{PrivilegesRequired} = $reader->ReadEnum(['None', 'PowerUser', 'Admin']);
	$ret->{ShowLanguageDialog} = $reader->ReadEnum(['Yes', 'No', 'Auto']);
	$ret->{LanguageDetectionMethod} = $reader->ReadEnum(['UILanguage', 'Locale', 'None']);
	$ret->{Options} = $reader->ReadSet(['DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'DisableAppendDir', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage', 'BzipUsed', 'AllowUNCPath', 'UserInfoPage', 'UsePreviousUserInfo', 'UninstallRestartComputer', 'RestartIfNeededByRun', 'ShowTasksTreeLines', 'AllowCancelDuringInstall']);
	# Unsupported data blocks
	$ret->{NumCustomMessageEntries} = 0;
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
  { Guessed } TSIDIdentifierAuthority: Array[0..11] of Byte;
  TGrantPermissionSid = record
    Authority: TSIDIdentifierAuthority;
    SubAuthCount: Byte;
    SubAuth: array[0..1] of DWORD;
  end;
  { TGrantPermissionEntry is stored inside string fields named 'Permissions' }
  TGrantPermissionEntry = record
    Sid: TGrantPermissionSid;
    AccessMask: DWORD;
  end;
  TSetupPermissionEntry = packed record
    Permissions: AnsiString;  { an array of TGrantPermissionEntry's }
  end;
=cut
sub SetupPermissions {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my $permissions = $reader->ReadString();
		$ret->[$i]->{Permissions} = $permissions;
		# There can be multiple entries, but how many?
		# Let's just leave out the unpacking for now
		#my $unpacked = { };
		#($unpacked->{Authority}, $unpacked->{SubAuthCount}, $unpacked->{SubAuth0}, $unpacked->{SubAuth1}, $unpacked->{AccessMask}) = unpack('(a12CL3)<', $permissions);
		#$ret->[$i] = $unpacked;
	}
	return $ret;
}

=comment
  TSetupLanguageEntry = packed record
    { Note: LanguageName is probably Unicode (test!) }
    Name, LanguageName, DialogFontName, TitleFontName, WelcomeFontName,
      CopyrightFontName, Data, LicenseText, InfoBeforeText,
      InfoAfterText: String;
    LanguageID: Cardinal;
    DialogFontSize: Integer;
    TitleFontSize: Integer;
    WelcomeFontSize: Integer;
    CopyrightFontSize: Integer;
  end;
=cut
sub SetupLanguages {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = ('Name', 'LanguageName', 'DialogFontName', 'TitleFontName', 'WelcomeFontName', 'CopyrightFontName', 'Data', 'LicenseText', 'InfoBeforeText', 'InfoAfterText');
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		# This is probably a wide string, but encoded as a regular one (length = number of bytes, not characters)
		#$ret->[$i]->{LanguageName} = decode('UTF-16LE', $ret->[$i]->{LanguageName});
		$ret->[$i]->{LanguageID} = $reader->ReadCardinal();
		$ret->[$i]->{DialogFontSize} = $reader->ReadInteger();
		$ret->[$i]->{TitleFontSize} = $reader->ReadInteger();
		$ret->[$i]->{WelcomeFontSize} = $reader->ReadInteger();
		$ret->[$i]->{CopyrightFontSize} = $reader->ReadInteger();
	}
	return $ret;
}

=comment
  TSetupDirEntry = packed record
    DirName: String;
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    PermissionsEntry: Smallint;
    Options: set of (doUninsNeverUninstall, doDeleteAfterInstall,
      doUninsAlwaysUninstall);
  end;
=cut
sub SetupDirs {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = ('DirName', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{PermissionsEntry} = $self->ReadSmallInt();
		$ret->[$i]->{Options} = $reader->ReadSet(['UninsNeverUninstall', 'DeleteAfterInstall', 'UninsAlwaysUninstall']);
	}
	return $ret;
}

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
      foPromptIfOlder, foDontCopy, foUninsRemoveReadOnly);
    FileType: (ftUserFile, ftUninstExe, ftRegSvrExe);
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
		$ret->[$i]->{Options} = $reader->ReadSet(['ConfirmOverwrite', 'UninsNeverUninstall', 'RestartReplace', 'DeleteAfterInstall', 'RegisterServer', 'RegisterTypeLib', 'SharedFile', 'CompareTimeStamp', 'FontIsntTrueType', 'SkipIfSourceDoesntExist', 'OverwriteReadOnly', 'OverwriteSameVersion', 'CustomDestName', 'OnlyIfDestFileExists', 'NoRegError', 'UninsRestartDelete', 'OnlyIfDoesntExist', 'IgnoreVersion', 'PromptIfOlder', 'DontCopy', 'UninsRemoveReadOnly']);
		$ret->[$i]->{FileType} = $reader->ReadEnum(['UserFile', 'UninstExe', 'RegSvrExe']);
	}
	return $ret;
}

=comment
  TSetupFileLocationEntry = packed record
    FirstSlice, LastSlice: Integer;
    StartOffset: Longint;
    ChunkSuboffset: Integer64;
    OriginalSize: Integer64;
    ChunkCompressedSize: Integer64;
    CRC: Longint;
    TimeStamp: TFileTime;
    FileVersionMS, FileVersionLS: DWORD;
    Flags: set of (foVersionInfoValid, foVersionInfoNotValid, foTimeStampInUTC
      foIsUninstExe);
  end;
=cut
sub SetupFileLocations {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		$ret->[$i]->{FirstSlice} = $reader->ReadInteger();
		$ret->[$i]->{LastSlice} = $reader->ReadInteger();
		$ret->[$i]->{StartOffset} = $reader->ReadLongInt();
		$ret->[$i]->{ChunkSuboffset} = $reader->ReadInteger64();
		$ret->[$i]->{OriginalSize} = $reader->ReadInteger64();
		$ret->[$i]->{ChunkCompressedSize} = $reader->ReadInteger64();
		$ret->[$i]->{Checksum} = $reader->ReadLongInt();
		$ret->[$i]->{TimeStamp} = $self->ReadFileTime($reader);
		$ret->[$i]->{FileVersionMS} = $reader->ReadLongWord();
		$ret->[$i]->{FileVersionLS} = $reader->ReadLongWord();
		$ret->[$i]->{Flags} = $reader->ReadSet(['VersionInfoValid', 'VersionInfoNotValid', 'TimeStampInUTC', 'IsUninstExe']);
		if ($ret->[$i]->{Flags}->{TimeStampInUTC}) {
			$ret->[$i]->{TimeStamp}->set_time_zone('UTC');
		}
		# Non-configurable settings
		$ret->[$i]->{Flags}->{ChunkCompressed} = 1;
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
      ioUseAppPaths);
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
		$ret->[$i]->{Options} = $reader->ReadSet(['UninsNeverUninstall', 'CreateOnlyIfFileExists', 'UseAppPaths']);
	}
	return $ret;
}

=comment
  TSetupIniEntry = packed record
    Filename, Section, Entry, Value: String;
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
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
		my @strings = ('Filename', 'Section', 'Entry', 'Value', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet(['CreateKeyIfDoesntExist', 'UninsDeleteEntry', 'UninsDeleteEntireSection', 'UninsDeleteSectionIfEmpty', 'HasValue']);
	}
	return $ret;
}

=comment
  TSetupRegistryEntry = packed record
    Subkey, ValueName, ValueData: String;
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    Permissions: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    RootKey: HKEY;
    PermissionsEntry: Smallint;
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
		my @strings = ('Subkey', 'ValueName', 'ValueData', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{RootKey} = $reader->ReadLongWord(); # HKEY
		$ret->[$i]->{PermissionsEntry} = $reader->ReadSmallInt();
		$ret->[$i]->{Typ} = $reader->ReadEnum(['None', 'String', 'ExpandString', 'DWord', 'Binary', 'MultiString']);
		$ret->[$i]->{Options} = $reader->ReadSet(['CreateValueIfDoesntExist', 'UninsDeleteValue', 'UninsClearValue', 'UninsDeleteEntireKey', 'UninsDeleteEntireKeyIfEmpty', 'PreserveStringType', 'DeleteKey', 'DeleteValue', 'NoError', 'DontCreateKey']);
	}
	return $ret;
}

=comment
  TSetupDeleteType = (dfFiles, dfFilesAndOrSubdirs, dfDirIfEmpty);
  TSetupDeleteEntry = packed record
    Name: String;
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
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
		my @strings = ('Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->{$name}->{$string} = $reader->ReadString();
		}
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{DeleteType} = $reader->ReadEnum(['Files', 'FilesAndOrSubdirs', 'DirIfEmpty']);
	}
	return $ret;
}

=comment
  TSetupRunEntry = packed record
    Name, Parameters, WorkingDir, RunOnceId, StatusMsg: String;
    Description, Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
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
		my @strings = ('Parameters', 'WorkingDir', 'RunOnceId', 'StatusMsg', 'Description', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
		for my $string (@strings) {
			$ret->{$name}->{$string} = $reader->ReadString();
		}
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{ShowCmd} = $reader->ReadInteger();
		$ret->{$name}->{Wait} = $reader->ReadEnum(['WaitUntilTerminated', 'NoWait', 'WaitUntilIdle']);
		$ret->{$name}->{Options} = $reader->ReadSet(['ShellExec', 'SkipIfDoesntExist', 'PostInstall', 'Unchecked', 'SkipIfSilent', 'SkipIfNotSilent', 'HideWizard']);
	}
	return $ret;
}

1;

