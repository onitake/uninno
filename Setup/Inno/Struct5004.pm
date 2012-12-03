#!/usr/bin/perl

package Setup::Inno::Struct5004;

use strict;
use base qw(Setup::Inno::Struct5003);

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
    shAppendDefaultGroupName, shEncryptionUsed, shChangesEnvironment);
  TSetupCompressMethod = (cmStored, cmZip, cmBzip, cmLZMA);
  TSetupSalt = array[0..7] of Byte;
  TSetupHeader = packed record
    AppName, AppVerName, AppId, AppCopyright, AppPublisher, AppPublisherURL,
      AppSupportURL, AppUpdatesURL, AppVersion, DefaultDirName,
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
    Options: set of TSetupHeaderOption;
  end;
=cut
sub SetupHeader {
	my ($self, $reader) = @_;
	my $ret = { };
	my @strings = ('AppName', 'AppVerName', 'AppId', 'AppCopyright', 'AppPublisher', 'AppPublisherURL', 'AppSupportURL', 'AppUpdatesURL', 'AppVersion', 'DefaultDirName', 'DefaultGroupName', 'BaseFilename', 'LicenseText', 'InfoBeforeText', 'InfoAfterText', 'UninstallFilesDir', 'UninstallDisplayName', 'UninstallDisplayIcon', 'AppMutex', 'DefaultUserInfoName', 'DefaultUserInfoOrg', 'DefaultUserInfoSerial', 'CompiledCodeText', 'AppReadmeFile', 'AppContact', 'AppComments', 'AppModifyPath');
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
	$ret->{Options} = $reader->ReadSet(['DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage', 'AllowUNCPath', 'UserInfoPage', 'UsePreviousUserInfo', 'UninstallRestartComputer', 'RestartIfNeededByRun', 'ShowTasksTreeLines', 'AllowCancelDuringInstall', 'WizardImageStretch', 'AppendDefaultDirName', 'AppendDefaultGroupName', 'EncryptionUsed', 'ChangesEnvironment']);
	return $ret;
}

1;
