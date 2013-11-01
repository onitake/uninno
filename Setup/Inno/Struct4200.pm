#!/usr/bin/perl

package Setup::Inno::Struct4200;

use strict;
use base qw(Setup::Inno::Struct4108);
use Digest;

sub CheckFile {
	my ($self, $data, $location) = @_;
	my $digest = Digest->new('MD5');
	$digest->add($data);
	return $digest->digest() eq $location->{Checksum};
}

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
    shAppendDefaultGroupName);
  TSetupCompressMethod = (cmZip, cmBzip, cmLZMA);
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
    Password: TMD5Digest;
    ExtraDiskSpaceRequired: Integer64;
    SlicesPerDisk: Integer;
    InstallMode: (imNormal, imSilent, imVerySilent);
    UninstallLogMode: (lmAppend, lmNew, lmOverwrite);
    UninstallStyle: (usClassic, usModern);
    DirExistsWarning: (ddAuto, ddNo, ddYes);
    PrivilegesRequired: (prNone, prPowerUser, prAdmin);
    ShowLanguageDialog: (slYes, slNo, slAuto);
    LanguageDetectionMethod: (ldUILanguage, ldLocale, ldNone);
    CompressMethod: TSetupCompressMethod;
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
	$ret->{Password} = $reader->ReadByteArray(16);
	$ret->{ExtraDiskSpaceRequired} = $reader->ReadInteger64();
	$ret->{SlicesPerDisk} = $reader->ReadInteger();
	$ret->{InstallMode} = $reader->ReadEnum(['Normal', 'Silent', 'VerySilent']);
	$ret->{UninstallLogMode} = $reader->ReadEnum(['Append', 'New', 'Overwrite']);
	$ret->{UninstallStyle} = $reader->ReadEnum(['Classic', 'Modern']);
	$ret->{DirExistsWarning} = $reader->ReadEnum(['Auto', 'No', 'Yes']);
	$ret->{PrivilegesRequired} = $reader->ReadEnum(['None', 'PowerUser', 'Admin']);
	$ret->{ShowLanguageDialog} = $reader->ReadEnum(['Yes', 'No', 'Auto']);
	$ret->{LanguageDetectionMethod} = $reader->ReadEnum(['UILanguage', 'Locale', 'None']);
	$ret->{CompressMethod} = $reader->ReadEnum(['Zip', 'Bzip', 'Lzma']);
	$ret->{Options} = $reader->ReadSet(['DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage', 'AllowUNCPath', 'UserInfoPage', 'UsePreviousUserInfo', 'UninstallRestartComputer', 'RestartIfNeededByRun', 'ShowTasksTreeLines', 'AllowCancelDuringInstall', 'WizardImageStretch', 'AppendDefaultDirName', 'AppendDefaultGroupName']);
	# Unsupported data blocks
	$ret->{NumCustomMessageEntries} = 0;
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
      foIsUninstExe, foCallInstructionOptimized, foTouch);
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
		$ret->[$i]->{Flags} = $reader->ReadSet(['VersionInfoValid', 'VersionInfoNotValid', 'TimeStampInUTC', 'IsUninstExe', 'CallInstructionOptimized', 'Touch']);
		if ($ret->[$i]->{Flags}->{TimeStampInUTC}) {
			$ret->[$i]->{TimeStamp}->set_time_zone('UTC');
		}
		# Non-configurable settings
		$ret->[$i]->{Flags}->{ChunkCompressed} = 1;
	}
	return $ret;
}

1;

