#!/usr/bin/perl

package Setup::Inno::Struct5203;

use strict;
use base qw(Setup::Inno::Struct5200);
use Encode;
use DateTime;

=comment
  TSetupVersionData = packed record
    WinVersion, NTVersion: Cardinal;
    NTServicePack: Word;
  end;
=cut
sub ReadVersion {
	my ($self, $reader) = @_;
	my $ret = { };
	$ret->{Win} = $reader->ReadCardinal();
	$ret->{Nt} = $reader->ReadCardinal();
	$ret->{ServicePack} = $reader->ReadWord();
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
    shPassword, shAllowRootDirectory, shDisableFinishedPage,
    shChangesAssociations, shCreateUninstallRegKey, shUsePreviousAppDir,
    shBackColorHorizontal, shUsePreviousGroup, shUpdateUninstallLogAppName,
    shUsePreviousSetupType, shDisableReadyMemo, shAlwaysShowComponentsList,
    shFlatComponentsList, shShowComponentSizes, shUsePreviousTasks,
    shDisableReadyPage, shAlwaysShowDirOnReadyPage, shAlwaysShowGroupOnReadyPage,
    shAllowUNCPath, shUserInfoPage, shUsePreviousUserInfo,
    shUninstallRestartComputer, shRestartIfNeededByRun, shShowTasksTreeLines,
    shAllowCancelDuringInstall, shWizardImageStretch, shAppendDefaultDirName,
    shAppendDefaultGroupName, shEncryptionUsed, shChangesEnvironment,
    shShowUndisplayableLanguages, shSetupLogging, shSignedUninstaller);
  TMD5Digest = array[0..15] of Byte;
  TSetupCompressMethod = (cmStored, cmZip, cmBzip, cmLZMA);
  TSetupSalt = array[0..7] of Byte;
  TSetupProcessorArchitecture = (paUnknown, paX86, paX64, paIA64);
  TSetupProcessorArchitectures = set of TSetupProcessorArchitecture;
  TSetupHeader = packed record
    AppName, AppVerName, AppId, AppCopyright, AppPublisher, AppPublisherURL,
      AppSupportPhone, AppSupportURL, AppUpdatesURL, AppVersion, DefaultDirName,
      DefaultGroupName, BaseFilename, LicenseText,
      InfoBeforeText, InfoAfterText, UninstallFilesDir, UninstallDisplayName,
      UninstallDisplayIcon, AppMutex, DefaultUserInfoName,
      DefaultUserInfoOrg, DefaultUserInfoSerial, CompiledCodeText,
      AppReadmeFile, AppContact, AppComments, AppModifyPath,
      SignedUninstallerSignature: String;
    LeadBytes: set of Char;
    NumLanguageEntries, NumCustomMessageEntries, NumPermissionEntries,
      NumTypeEntries, NumComponentEntries, NumTaskEntries, NumDirEntries,
      NumFileEntries, NumFileLocationEntries, NumIconEntries, NumIniEntries,
      NumRegistryEntries, NumInstallDeleteEntries, NumUninstallDeleteEntries,
      NumRunEntries, NumUninstallRunEntries: Integer;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    BackColor, BackColor2, WizardImageBackColor: Longint;
    PasswordHash: TMD5Digest;
    PasswordSalt: TSetupSalt;
    ExtraDiskSpaceRequired: Integer64;
    SlicesPerDisk: Integer;
    UninstallLogMode: (lmAppend, lmNew, lmOverwrite);
    DirExistsWarning: (ddAuto, ddNo, ddYes);
    PrivilegesRequired: (prNone, prPowerUser, prAdmin);
    ShowLanguageDialog: (slYes, slNo, slAuto);
    LanguageDetectionMethod: (ldUILanguage, ldLocale, ldNone);
    CompressMethod: TSetupCompressMethod;
    ArchitecturesAllowed, ArchitecturesInstallIn64BitMode: TSetupProcessorArchitectures;
    SignedUninstallerOrigSize: LongWord;
    SignedUninstallerHdrChecksum: DWORD;
    Options: set of TSetupHeaderOption;
  end;
=cut
sub SetupHeader {
	my ($self, $reader) = @_;
	my $ret = { };
	my @strings = qw"AppName AppVerName AppId AppCopyright AppPublisher AppPublisherURL AppSupportPhone AppSupportURL AppUpdatesURL AppVersion DefaultDirName DefaultGroupName BaseFilename LicenseText InfoBeforeText InfoAfterText UninstallFilesDir UninstallDisplayName UninstallDisplayIcon AppMutex DefaultUserInfoName DefaultUserInfoOrg DefaultUserInfoSerial CompiledCodeText AppReadmeFile AppContact AppComments AppModifyPath SignedUninstallerSignature";
	for my $string (@strings) {
		$ret->{$string} = $reader->ReadString();
	}
	$ret->{LeadBytes} = $reader->ReadSet(256);
	my @integers = qw"NumLanguageEntries NumCustomMessageEntries NumPermissionEntries NumTypeEntries NumComponentEntries NumTaskEntries NumDirEntries NumFileEntries NumFileLocationEntries NumIconEntries NumIniEntries NumRegistryEntries NumInstallDeleteEntries NumUninstallDeleteEntries NumRunEntries NumUninstallRunEntries";
	for my $integer (@integers) {
		$ret->{$integer} = $reader->ReadInteger();
	}
	$ret->{MinVersion} = $self->ReadVersion($reader);
	$ret->{OnlyBelowVersion} = $self->ReadVersion($reader);
	$ret->{BackColor} = $reader->ReadLongInt();
	$ret->{BackColor2} = $reader->ReadLongInt();
	$ret->{WizardImageBackColor} = $reader->ReadLongInt();
	$ret->{PasswordHash} = $reader->ReadByteArray(16);
	$ret->{PasswordSalt} = $reader->ReadByteArray(8);
	$ret->{ExtraDiskSpaceRequired} = $reader->ReadInteger64();
	$ret->{SlicesPerDisk} = $reader->ReadInteger();
	$ret->{UninstallLogMode} = $reader->ReadEnum([ 'Append', 'New', 'Overwrite' ]);
	$ret->{DirExistsWarning} = $reader->ReadEnum([ 'Auto', 'No', 'Yes' ]);
	$ret->{PrivilegesRequired} = $reader->ReadEnum([ 'None', 'PowerUser', 'Admin' ]);
	$ret->{ShowLanguageDialog} = $reader->ReadEnum([ 'Yes', 'No', 'Auto' ]);
	$ret->{LanguageDetectionMethod} = $reader->ReadEnum([ 'UILanguage', 'Locale', 'None' ]);
	$ret->{CompressMethod} = $reader->ReadEnum([ 'Stored', 'Zip', 'Bzip', 'Lzma', ]);
	$ret->{ArchitecturesAllowed} = $reader->ReadSet([ 'Unknown', 'X86', 'X64', 'IA64' ]);
	$ret->{ArchitecturesInstallIn64BitMode} = $reader->ReadSet([ 'Unknown', 'X86', 'X64', 'IA64' ]);
	$ret->{SignedUninstallerOrigSize} = $reader->ReadLongWord();
	$ret->{SignedUninstallerHdrChecksum} = $reader->ReadLongWord();
	$ret->{Options} = $reader->ReadSet([ 'DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage', 'AllowUNCPath', 'UserInfoPage', 'UsePreviousUserInfo', 'UninstallRestartComputer', 'RestartIfNeededByRun', 'ShowTasksTreeLines', 'AllowCancelDuringInstall', 'WizardImageStretch', 'AppendDefaultDirName', 'AppendDefaultGroupName', 'EncryptionUsed', 'ChangesEnvironment', 'ShowUndisplayableLanguages', 'SetupLogging', 'SignedUninstaller' ]);
	return $ret;
}

=comment
  TSetupLanguageEntry = packed record
    { Note: LanguageName is Unicode }
    Name, LanguageName, DialogFontName, TitleFontName, WelcomeFontName,
      CopyrightFontName, Data, LicenseText, InfoBeforeText,
      InfoAfterText: String;
    LanguageID, LanguageCodePage: Cardinal;
    DialogFontSize: Integer;
    TitleFontSize: Integer;
    WelcomeFontSize: Integer;
    CopyrightFontSize: Integer;
    RightToLeft: Boolean;
  end;
=cut
sub SetupLanguages {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"Name LanguageName DialogFontName TitleFontName WelcomeFontName CopyrightFontName Data LicenseText InfoBeforeText InfoAfterText";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		# This is a wide string, but encoded as a regular one (length = number of bytes, not characters)
		$ret->[$i]->{LanguageName} = decode('UTF-16LE', $ret->[$i]->{LanguageName});
		$ret->[$i]->{LanguageID} = $reader->ReadCardinal();
		$ret->[$i]->{LanguageCodePage} = $reader->ReadCardinal();
		$ret->[$i]->{DialogFontSize} = $reader->ReadInteger();
		$ret->[$i]->{TitleFontSize} = $reader->ReadInteger();
		$ret->[$i]->{WelcomeFontSize} = $reader->ReadInteger();
		$ret->[$i]->{CopyrightFontSize} = $reader->ReadInteger();
		$ret->[$i]->{RightToLeft} = $reader->ReadBoolean();
	}
	return $ret;
}

=comment
  TSetupCustomMessageEntry = packed record
    Name, Value: String;
    LangIndex: Integer;
  end;
=cut
sub SetupCustomMessages {
	my ($self, $reader, $count) = @_;
	my $ret = { };
	for (my $i = 0; $i < $count; $i++) {
		my $name = $reader->ReadString();
		if (!$name) {
			# Rather use the index if the name is empty
			$name = $i;
		}
		$ret->{$name}->{Name} = $name;
		$ret->{$name}->{Value} = $reader->ReadString();
		$ret->{$name}->{LangIndex} = $reader->ReadInteger();
	}
	return $ret;
}

=comment
  { Guessed } TSIDIdentifierAuthority: Array[0..11] of Byte;
  TGrantPermissionSid = record  { must keep in synch with Helper.c }
    Authority: TSIDIdentifierAuthority;
    SubAuthCount: Byte;
    SubAuth: array[0..1] of DWORD;
  end;
  TGrantPermissionEntry = record  { must keep in synch with Helper.c }
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
  TSetupTypeOption = (toIsCustom);
  TSetupTypeOptions = set of TSetupTypeOption;
  TSetupTypeType = (ttUser, ttDefaultFull, ttDefaultCompact, ttDefaultCustom);
  PSetupTypeEntry = ^TSetupTypeEntry;
  TSetupTypeEntry = packed record
    Name, Description, Languages, Check: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: TSetupTypeOptions;
    Typ: TSetupTypeType;
    { internally used: }
    Size: Integer64;
  end;
=cut
sub SetupTypes {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"Name Description Languages Check";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'IsCustom' ]);
		$ret->[$i]->{Typ} = $reader->ReadEnum([ 'User', 'DefaultFull', 'DefaultCompact', 'DefaultCustom' ]);
		$ret->[$i]->{Size} = $reader->ReadInteger64();
	}
	return $ret;
}

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
		my @strings = qw"Description Types Languages Check";
		for my $string (@strings) {
			$ret->{$name}->{$string} = $reader->ReadString();
		}
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
		my @strings = qw"Name Description GroupDescription Components Languages Check";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{Level} = $reader->ReadInteger();
		$ret->[$i]->{Used} = $reader->ReadBoolean();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'Exclusive', 'Unchecked', 'Restart', 'CheckedOnce', 'DontInheritCheck' ]);
	}
	return $ret;
}

=comment
  TSetupDirEntry = packed record
    DirName: String;
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    Attribs: Integer;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    PermissionsEntry: Smallint;
    Options: set of (doUninsNeverUninstall, doDeleteAfterInstall,
      doUninsAlwaysUninstall, doSetNTFSCompression, doUnsetNTFSCompression);
  end;
=cut
sub SetupDirs {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"DirName Components Tasks Languages Check AfterInstall BeforeInstall";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{Attribs} = $reader->ReadInteger();
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{PermissionsEntry} = $reader->ReadSmallInt();
		$ret->[$i]->{Options} = $reader->ReadSet([ 'UninsNeverUninstall', 'DeleteAfterInstall', 'UninsAlwaysUninstall', 'SetNTFSCompression', 'UnsetNTFSCompression' ]);
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
      foPromptIfOlder, foDontCopy, foUninsRemoveReadOnly,
      foRecurseSubDirsExternal, foReplaceSameVersionIfContentsDiffer,
      foDontVerifyChecksum, foUninsNoSharedFilePrompt, foCreateAllSubDirs,
      fo32Bit, fo64Bit, foExternalSizePreset, foSetNTFSCompression,
      foUnsetNTFSCompression);
    FileType: (ftUserFile, ftUninstExe);
  end;
=cut
sub SetupFiles {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"SourceFilename DestName InstallFontName Components Tasks Languages Check AfterInstall BeforeInstall";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{LocationEntry} = $reader->ReadInteger();
		$ret->[$i]->{Attribs} = $reader->ReadInteger();
		$ret->[$i]->{ExternalSize} = $reader->ReadInteger64();
		$ret->[$i]->{PermissionsEntry} = $reader->ReadSmallInt();
		$ret->[$i]->{Options} = $reader->ReadSet([ 'ConfirmOverwrite', 'UninsNeverUninstall', 'RestartReplace', 'DeleteAfterInstall', 'RegisterServer', 'RegisterTypeLib', 'SharedFile', 'CompareTimeStamp', 'FontIsntTrueType', 'SkipIfSourceDoesntExist', 'OverwriteReadOnly', 'OverwriteSameVersion', 'CustomDestName', 'OnlyIfDestFileExists', 'NoRegError', 'UninsRestartDelete', 'OnlyIfDoesntExist', 'IgnoreVersion', 'PromptIfOlder', 'DontCopy', 'UninsRemoveReadOnly', 'RecurseSubDirsExternal', 'ReplaceSameVersionIfContentsDiffer', 'DontVerifyChecksum', 'UninsNoSharedFilePrompt', 'CreateAllSubDirs', '32Bit', '64Bit', 'ExternalSizePreset', 'SetNTFSCompression', 'UnsetNTFSCompression' ]);
		$ret->[$i]->{FileType} = $reader->ReadEnum([ 'UserFile', 'UninstExe' ]);
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
  TSetupIconCloseOnExit = (icNoSetting, icYes, icNo);
=cut
sub SetupIcons {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"IconName Filename Parameters WorkingDir IconFilename Comment Components Tasks Languages Check AfterInstall BeforeInstall";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{IconIndex} = $reader->ReadInteger();
		$ret->[$i]->{ShowCmd} = $reader->ReadInteger();
		$ret->[$i]->{CloseOnExit} = $reader->ReadEnum([ 'NoSetting', 'Yes', 'No' ]);
		$ret->[$i]->{HotKey} = $reader->ReadWord();
		$ret->[$i]->{Options} = $reader->ReadSet([ 'UninsNeverUninstall', 'CreateOnlyIfFileExists', 'UseAppPaths', 'FolderShortcut' ]);
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
		my @strings = qw"Filename Section Entry Value Components Tasks Languages Check AfterInstall BeforeInstall";
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
    Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    RootKey: HKEY;
    PermissionsEntry: Smallint;
    Typ: (rtNone, rtString, rtExpandString, rtDWord, rtBinary, rtMultiString);
    Options: set of (roCreateValueIfDoesntExist, roUninsDeleteValue,
      roUninsClearValue, roUninsDeleteEntireKey, roUninsDeleteEntireKeyIfEmpty,
      roPreserveStringType, roDeleteKey, roDeleteValue, roNoError,
      roDontCreateKey, ro32Bit, ro64Bit);
  end;
=cut
sub SetupRegistryEntries {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"Subkey ValueName ValueData Components Tasks Languages Check AfterInstall BeforeInstall";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{RootKey} = $reader->ReadLongWord(); # HKEY
		$ret->[$i]->{PermissionsEntry} = $reader->ReadSmallInt();
		$ret->[$i]->{Typ} = $reader->ReadEnum([ 'None', 'String', 'ExpandString', 'DWord', 'Binary', 'MultiString' ]);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'CreateValueIfDoesntExist', 'UninsDeleteValue', 'UninsClearValue', 'UninsDeleteEntireKey', 'UninsDeleteEntireKeyIfEmpty', 'PreserveStringType', 'DeleteKey', 'DeleteValue', 'NoError', 'DontCreateKey', '32Bit', '64Bit' ]);
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
		my @strings = qw"Components Tasks Languages Check AfterInstall BeforeInstall";
		for my $string (@strings) {
			$ret->{$name}->{$string} = $reader->ReadString();
		}
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{DeleteType} = $reader->ReadEnum([ 'Files', 'FilesAndOrSubdirs', 'DirIfEmpty' ]);
	}
	return $ret;
}

=comment
  TSetupRunEntry = packed record
    Name, Parameters, WorkingDir, RunOnceId, StatusMsg, Verb: String;
    Description, Components, Tasks, Languages, Check, AfterInstall, BeforeInstall: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    ShowCmd: Integer;
    Wait: (rwWaitUntilTerminated, rwNoWait, rwWaitUntilIdle);
    Options: set of (roShellExec, roSkipIfDoesntExist,
      roPostInstall, roUnchecked, roSkipIfSilent, roSkipIfNotSilent,
      roHideWizard, roRun32Bit, roRun64Bit, roRunAsOriginalUser);
  end;
=cut
sub SetupRun {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"Name Parameters WorkingDir RunOnceId StatusMsg Verb Description Components Tasks Languages Check AfterInstall BeforeInstall";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{ShowCmd} = $reader->ReadInteger();
		$ret->[$i]->{Wait} = $reader->ReadEnum([ 'WaitUntilTerminated', 'NoWait', 'WaitUntilIdle' ]);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'ShellExec', 'SkipIfDoesntExist', 'PostInstall', 'Unchecked', 'SkipIfSilent', 'SkipIfNotSilent', 'HideWizard', 'Run32Bit', 'Run64Bit', 'RunAsOriginalUser' ]);
	}
	return $ret;
}

=comment
          if Ver<4000 then with pFileLocationEntry^ do begin
            Dec(FirstSlice);
            Dec(LastSlice);
          end;
        for i:=0 to Entries[seFileLocation].Count-1 do
          if foTimeStampInUTC in PSetupFileLocationEntry(Entries[seFileLocation][i])^.Flags then begin
            TimeStampsInUTC:=true;
            break;
          end;
  TMD5Digest = array[0..15] of Byte;
typedef struct _FILETIME {
  DWORD dwLowDateTime;
  DWORD dwHighDateTime;
} FILETIME, *PFILETIME;
  TFileTime = _FILETIME;
  TSetupFileLocationEntry = packed record
    FirstSlice, LastSlice: Integer;
    StartOffset: Longint;
    ChunkSuboffset: Integer64;
    OriginalSize: Integer64;
    ChunkCompressedSize: Integer64;
    MD5Sum: TMD5Digest;
    TimeStamp: TFileTime;
    FileVersionMS, FileVersionLS: DWORD;
    Flags: set of (foVersionInfoValid, foVersionInfoNotValid, foTimeStampInUTC,
      foIsUninstExe, foCallInstructionOptimized, foTouch, foChunkEncrypted,
      foChunkCompressed, foSolidBreak);
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
		$ret->[$i]->{Checksum} = $reader->ReadByteArray(16);
		# 100-nanosecond intervals since January 1, 1601 (UTC).
		my $tlow = $reader->ReadLongWord();
		my $thigh = $reader->ReadLongWord();
		# Extract seconds so we don't exceed 64 bits
		my $hnsecs = $tlow | ($thigh << 32);
		my $secs = int($hnsecs / 10000000);
		my $nsecs = ($hnsecs - $secs * 10000000) * 100;
		$ret->[$i]->{FileVersionMS} = $reader->ReadLongWord();
		$ret->[$i]->{FileVersionLS} = $reader->ReadLongWord();
		$ret->[$i]->{Flags} = $reader->ReadSet([ 'VersionInfoValid', 'VersionInfoNotValid', 'TimeStampInUTC', 'IsUninstExe', 'CallInstructionOptimized', 'Touch', 'ChunkEncrypted', 'ChunkCompressed', 'SolidBreak' ]);
		if ($ret->[$i]->{Flags}->{TimeStampInUTC}) {
			# UTC
			$ret->[$i]->{TimeStamp} = DateTime->new(year => 1601, month => 1, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0, time_zone => 'UTC')->add(seconds => $secs, nanoseconds => $nsecs);
		} else {
			# Unknown timezone
			$ret->[$i]->{TimeStamp} = DateTime->new(year => 1601, month => 1, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0)->add(seconds => $secs, nanoseconds => $nsecs);
		}
	}
	return $ret;
}

1;

