#!/usr/bin/perl

package Setup::Inno::Struct5113;

use strict;
use base qw(Setup::Inno::Struct5110);

=comment
  TMD5Digest = array[0..15] of Byte;
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
    shShowUndisplayableLanguages, shSetupLogging);
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
      AppReadmeFile, AppContact, AppComments, AppModifyPath: String;
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
    Options: set of TSetupHeaderOption;
  end;
=cut
sub SetupHeader {
	my ($self, $reader) = @_;
	my $ret = { };
	my @strings = ('AppName', 'AppVerName', 'AppId', 'AppCopyright', 'AppPublisher', 'AppPublisherURL', 'AppSupportPhone', 'AppSupportURL', 'AppUpdatesURL', 'AppVersion', 'DefaultDirName', 'DefaultGroupName', 'BaseFilename', 'LicenseText', 'InfoBeforeText', 'InfoAfterText', 'UninstallFilesDir', 'UninstallDisplayName', 'UninstallDisplayIcon', 'AppMutex', 'DefaultUserInfoName', 'DefaultUserInfoOrg', 'DefaultUserInfoSerial', 'CompiledCodeText', 'AppReadmeFile', 'AppContact', 'AppComments', 'AppModifyPath');
	for my $string (@strings) {
		$ret->{$string} = $reader->ReadString();
	}
	$ret->{LeadBytes} = $reader->ReadSet(256);
	my @integers = ('NumLanguageEntries', 'NumCustomMessageEntries', 'NumPermissionEntries', 'NumTypeEntries', 'NumComponentEntries', 'NumTaskEntries', 'NumDirEntries', 'NumFileEntries', 'NumFileLocationEntries', 'NumIconEntries', 'NumIniEntries', 'NumRegistryEntries', 'NumInstallDeleteEntries', 'NumUninstallDeleteEntries', 'NumRunEntries', 'NumUninstallRunEntries');
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
	$ret->{UninstallLogMode} = $reader->ReadEnum(['Append', 'New', 'Overwrite']);
	$ret->{DirExistsWarning} = $reader->ReadEnum(['Auto', 'No', 'Yes']);
	$ret->{PrivilegesRequired} = $reader->ReadEnum(['None', 'PowerUser', 'Admin']);
	$ret->{ShowLanguageDialog} = $reader->ReadEnum(['Yes', 'No', 'Auto']);
	$ret->{LanguageDetectionMethod} = $reader->ReadEnum(['UILanguage', 'Locale', 'None']);
	$ret->{CompressMethod} = $reader->ReadEnum(['Stored', 'Zip', 'Bzip', 'Lzma']);
	$ret->{ArchitecturesAllowed} = $reader->ReadSet(['Unknown', 'X86', 'X64', 'IA64']);
	$ret->{ArchitecturesInstallIn64BitMode} = $reader->ReadSet(['Unknown', 'X86', 'X64', 'IA64']);
	$ret->{Options} = $reader->ReadSet(['DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage', 'AllowUNCPath', 'UserInfoPage', 'UsePreviousUserInfo', 'UninstallRestartComputer', 'RestartIfNeededByRun', 'ShowTasksTreeLines', 'AllowCancelDuringInstall', 'WizardImageStretch', 'AppendDefaultDirName', 'AppendDefaultGroupName', 'EncryptionUsed', 'ChangesEnvironment', 'ShowUndisplayableLanguages', 'SetupLogging']);
	return $ret;
}

=comment
  TMD5Digest = array[0..15] of Byte;
  TSetupFileLocationEntry = packed record
    FirstSlice, LastSlice: Integer;
    StartOffset: Longint;
    ChunkSuboffset: Integer64;
    OriginalSize: Integer64;
    ChunkCompressedSize: Integer64;
    MD5Sum: TMD5Digest;
    TimeStamp: TFileTime;
    FileVersionMS, FileVersionLS: DWORD;
    Flags: set of (foVersionInfoValid, foVersionInfoNotValid, foTimeStampInUTC
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
		$ret->[$i]->{TimeStamp} = $self->ReadFileTime($reader);
		$ret->[$i]->{FileVersionMS} = $reader->ReadLongWord();
		$ret->[$i]->{FileVersionLS} = $reader->ReadLongWord();
		$ret->[$i]->{Flags} = $reader->ReadSet(['VersionInfoValid', 'VersionInfoNotValid', 'TimeStampInUTC', 'IsUninstExe', 'CallInstructionOptimized', 'Touch', 'ChunkEncrypted', 'ChunkCompressed', 'SolidBreak']);
		if ($ret->[$i]->{Flags}->{TimeStampInUTC}) {
			$ret->[$i]->{TimeStamp}->set_time_zone('UTC');
		}
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
		my @strings = ('Parameters', 'WorkingDir', 'RunOnceId', 'StatusMsg', 'Verb', 'Description', 'Components', 'Tasks', 'Languages', 'Check', 'AfterInstall', 'BeforeInstall');
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
