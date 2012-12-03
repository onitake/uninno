#!/usr/bin/perl

package Setup::Inno::Struct4103;

use strict;
use base qw(Setup::Inno::Struct4102);

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
    shBzipUsed, shAllowUNCPath, shUserInfoPage, shUsePreviousUserInfo
    shUninstallRestartComputer, shRestartIfNeededByRun, shShowTasksTreeLines,
    shAllowCancelDuringInstall, shWizardImageStretch);
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
	$ret->{Options} = $reader->ReadSet(['DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage', 'BzipUsed', 'AllowUNCPath', 'UserInfoPage', 'UsePreviousUserInfo', 'UninstallRestartComputer', 'RestartIfNeededByRun', 'ShowTasksTreeLines', 'AllowCancelDuringInstall', 'WizardImageStretch']);
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

1;

