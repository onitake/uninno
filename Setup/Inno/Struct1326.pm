package Setup::Inno::Struct1326;
use strict;
use base 'Setup::Inno::Struct';
sub TSetupHeader {
	my ($self) = @_;
	my $ret;
	$ret = {
		AppName => $self->ReadString(1),
		AppVerName => $self->ReadString(1),
		AppId => $self->ReadString(1),
		AppCopyright => $self->ReadString(1),
		AppPublisher => $self->ReadString(1),
		AppPublisherURL => $self->ReadString(1),
		AppSupportURL => $self->ReadString(1),
		AppUpdatesURL => $self->ReadString(1),
		AppVersion => $self->ReadString(1),
		DefaultDirName => $self->ReadString(1),
		DefaultGroupName => $self->ReadString(1),
		UninstallIconName => $self->ReadString(1),
		BaseFilename => $self->ReadString(1),
		LicenseText => $self->ReadString(1),
		InfoBeforeText => $self->ReadString(1),
		InfoAfterText => $self->ReadString(1),
		UninstallFilesDir => $self->ReadString(1),
		UninstallDisplayName => $self->ReadString(1),
		UninstallDisplayIcon => $self->ReadString(1),
		AppMutex => $self->ReadString(1),
		NumDirEntries => $self->ReadInteger(),
		NumFileEntries => $self->ReadInteger(),
		NumFileLocationEntries => $self->ReadInteger(),
		NumIconEntries => $self->ReadInteger(),
		NumIniEntries => $self->ReadInteger(),
		NumRegistryEntries => $self->ReadInteger(),
		NumInstallDeleteEntries => $self->ReadInteger(),
		NumUninstallDeleteEntries => $self->ReadInteger(),
		NumRunEntries => $self->ReadInteger(),
		NumUninstallRunEntries => $self->ReadInteger(),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		BackColor => $self->ReadLongInt(),
		BackColor2 => $self->ReadLongInt(),
		WizardImageBackColor => $self->ReadLongInt(),
		Password => $self->ReadLongInt(),
		ExtraDiskSpaceRequired => $self->ReadLongInt(),
		UninstallLogMode => $self->ReadEnum([ 'lmAppend', 'lmNew', 'lmOverwrite' ]),
		DirExistsWarning => $self->ReadEnum([ 'ddAuto', 'ddNo', 'ddYes' ]),
		Options => $self->ReadSet([ 'shDisableStartupPrompt', 'shUninstallable', 'shCreateAppDir', 'shDisableDirPage', 'shDisableProgramGroupPage', 'shAllowNoIcons', 'shAlwaysRestart', 'shAlwaysUsePersonalGroup', 'shWindowVisible', 'shWindowShowCaption', 'shWindowResizable', 'shWindowStartMaximized', 'shEnableDirDoesntExistWarning', 'shDisableAppendDir', 'shPassword', 'shAllowRootDirectory', 'shDisableFinishedPage', 'shAdminPrivilegesRequired', 'shAlwaysCreateUninstallIcon', 'shChangesAssociations', 'shCreateUninstallRegKey', 'shUsePreviousAppDir', 'shBackColorHorizontal', 'shUsePreviousGroup', 'shUpdateUninstallLogAppName' ]),
	};
	return $ret;
}
sub TSetupDirEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		DirName => $self->ReadString(1),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		Options => $self->ReadSet([ 'doUninsNeverUninstall', 'doDeleteAfterInstall', 'doUninsAlwaysUninstall' ]),
	};
	return $ret;
}
sub TSetupFileEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		SourceFilename => $self->ReadString(1),
		DestName => $self->ReadString(1),
		InstallFontName => $self->ReadString(1),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		LocationEntry => $self->ReadInteger(),
		Attribs => $self->ReadInteger(),
		ExternalSize => $self->ReadLongInt(),
		CopyMode => $self->ReadEnum([ 'cmNormal', 'cmIfDoesntExist', 'cmAlwaysOverwrite', 'cmAlwaysSkipIfSameOrOlder' ]),
		Options => $self->ReadSet([ 'foConfirmOverwrite', 'foUninsNeverUninstall', 'foRestartReplace', 'foDeleteAfterInstall', 'foRegisterServer', 'foRegisterTypeLib', 'foSharedFile', 'foIsReadmeFile', 'foCompareTimeStampAlso', 'foFontIsntTrueType', 'foSkipIfSourceDoesntExist', 'foOverwriteReadOnly', 'foOverwriteSameVersion', 'foCustomDestName', 'foOnlyIfDestFileExists' ]),
		FileType => $self->ReadEnum([ 'ftUserFile', 'ftUninstExe', 'ftRegSvrExe' ]),
	};
	return $ret;
}
sub TSetupIconEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		IconName => $self->ReadString(1),
		Filename => $self->ReadString(1),
		Parameters => $self->ReadString(1),
		WorkingDir => $self->ReadString(1),
		IconFilename => $self->ReadString(1),
		Comment => $self->ReadString(1),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		IconIndex => $self->ReadInteger(),
		ShowCmd => $self->ReadInteger(),
		CloseOnExit => $self->ReadEnum([ 'icNoSetting', 'icYes', 'icNo' ]),
		Options => $self->ReadSet([ 'ioUninsNeverUninstall', 'ioCreateOnlyIfFileExists', 'ioUseAppPaths' ]),
	};
	return $ret;
}
sub TSetupIniEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Filename => $self->ReadString(1),
		Section => $self->ReadString(1),
		Entry => $self->ReadString(1),
		Value => $self->ReadString(1),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		Options => $self->ReadSet([ 'ioCreateKeyIfDoesntExist', 'ioUninsDeleteEntry', 'ioUninsDeleteEntireSection', 'ioUninsDeleteSectionIfEmpty', 'ioHasValue' ]),
	};
	return $ret;
}
sub TSetupRegistryEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Subkey => $self->ReadString(1),
		ValueName => $self->ReadString(1),
		ValueData => $self->ReadString(1),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		RootKey => $self->HKEY(),
		Typ => $self->ReadEnum([ 'rtNone', 'rtString', 'rtExpandString', 'rtDWord', 'rtBinary', 'rtMultiString' ]),
		Options => $self->ReadSet([ 'roCreateValueIfDoesntExist', 'roUninsDeleteValue', 'roUninsClearValue', 'roUninsDeleteEntireKey', 'roUninsDeleteEntireKeyIfEmpty', 'roPreserveStringType', 'roDeleteKey', 'roDeleteValue', 'roNoError', 'roDontCreateKey' ]),
	};
	return $ret;
}
sub TSetupDeleteEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		DeleteType => $self->ReadEnum([ 'dfFiles', 'dfFilesAndOrSubdirs', 'dfDirIfEmpty' ]),
	};
	return $ret;
}
sub TSetupRunEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		Parameters => $self->ReadString(1),
		WorkingDir => $self->ReadString(1),
		RunOnceId => $self->ReadString(1),
		MinVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $self->ReadCardinal(),
			NTVersion => $self->ReadCardinal(),
			NTServicePack => $self->ReadWord(),
		},
		ShowCmd => $self->ReadInteger(),
		Wait => $self->ReadEnum([ 'rwWaitUntilTerminated', 'rwNoWait', 'rwWaitUntilIdle' ]),
		Options => $self->ReadSet([ 'roShellExec', 'roSkipIfDoesntExist' ]),
	};
	return $ret;
}
sub TSetupFileLocationEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		FirstDisk => $self->ReadInteger(),
		LastDisk => $self->ReadInteger(),
		StartOffset => $self->ReadLongInt(),
		OriginalSize => $self->ReadLongInt(),
		CompressedSize => $self->ReadLongInt(),
		Adler => $self->ReadLongInt(),
		Date => $self->TFileTime(),
		FileVersionMS => $self->DWORD(),
		FileVersionLS => $self->DWORD(),
		Flags => $self->ReadSet([ 'foVersionInfoValid', 'foVersionInfoNotValid' ]),
	};
	return $ret;
}
1;
