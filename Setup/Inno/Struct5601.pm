package Setup::Inno::Struct5601;
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
		AppSupportPhone => $self->ReadString(1),
		AppSupportURL => $self->ReadString(1),
		AppUpdatesURL => $self->ReadString(1),
		AppVersion => $self->ReadString(1),
		DefaultDirName => $self->ReadString(1),
		DefaultGroupName => $self->ReadString(1),
		BaseFilename => $self->ReadString(1),
		UninstallFilesDir => $self->ReadString(1),
		UninstallDisplayName => $self->ReadString(1),
		UninstallDisplayIcon => $self->ReadString(1),
		AppMutex => $self->ReadString(1),
		DefaultUserInfoName => $self->ReadString(1),
		DefaultUserInfoOrg => $self->ReadString(1),
		DefaultUserInfoSerial => $self->ReadString(1),
		AppReadmeFile => $self->ReadString(1),
		AppContact => $self->ReadString(1),
		AppComments => $self->ReadString(1),
		AppModifyPath => $self->ReadString(1),
		CreateUninstallRegKey => $self->ReadString(1),
		Uninstallable => $self->ReadString(1),
		CloseApplicationsFilter => $self->ReadString(1),
		SetupMutex => $self->ReadString(1),
		LicenseText => $self->ReadString(1),
		InfoBeforeText => $self->ReadString(1),
		InfoAfterText => $self->ReadString(1),
		CompiledCodeText => $self->ReadString(1),
		LeadBytes => $self->ReadSet(256),
		NumLanguageEntries => $self->ReadInteger(),
		NumCustomMessageEntries => $self->ReadInteger(),
		NumPermissionEntries => $self->ReadInteger(),
		NumTypeEntries => $self->ReadInteger(),
		NumComponentEntries => $self->ReadInteger(),
		NumTaskEntries => $self->ReadInteger(),
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
		WizardImageAlphaFormat => $self->ReadEnum([ 'afIgnored', 'afDefined', 'afPremultiplied' ]),
		PasswordHash => $self->TSHA1Digest(),
		PasswordSalt => [ map({ $self->ReadByte() } (0..7)) ],
		ExtraDiskSpaceRequired => $self->ReadInt64(),
		SlicesPerDisk => $self->ReadInteger(),
		UninstallLogMode => $self->ReadEnum([ 'lmAppend', 'lmNew', 'lmOverwrite' ]),
		DirExistsWarning => $self->ReadEnum([ 'ddAuto', 'ddNo', 'ddYes' ]),
		PrivilegesRequired => $self->ReadEnum([ 'prNone', 'prPowerUser', 'prAdmin', 'prLowest' ]),
		ShowLanguageDialog => $self->ReadEnum([ 'slYes', 'slNo', 'slAuto' ]),
		LanguageDetectionMethod => $self->ReadEnum([ 'ldUILanguage', 'ldLocale', 'ldNone' ]),
		CompressMethod => $self->ReadEnum([ 'cmStored', 'cmZip', 'cmBzip', 'cmLZMA', 'cmLZMA2' ]),
		ArchitecturesAllowed => $self->ReadSet([ 'paUnknown', 'paX86', 'paX64', 'paIA64', 'paARM64' ]),
		ArchitecturesInstallIn64BitMode => $self->ReadSet([ 'paUnknown', 'paX86', 'paX64', 'paIA64', 'paARM64' ]),
		DisableDirPage => $self->ReadEnum([ 'dpAuto', 'dpNo', 'dpYes' ]),
		DisableProgramGroupPage => $self->ReadEnum([ 'dpAuto', 'dpNo', 'dpYes' ]),
		UninstallDisplaySize => $self->ReadInt64(),
		Options => $self->ReadSet([ 'shDisableStartupPrompt', 'shCreateAppDir', 'shAllowNoIcons', 'shAlwaysRestart', 'shAlwaysUsePersonalGroup', 'shWindowVisible', 'shWindowShowCaption', 'shWindowResizable', 'shWindowStartMaximized', 'shEnableDirDoesntExistWarning', 'shPassword', 'shAllowRootDirectory', 'shDisableFinishedPage', 'shChangesAssociations', 'shUsePreviousAppDir', 'shBackColorHorizontal', 'shUsePreviousGroup', 'shUpdateUninstallLogAppName', 'shUsePreviousSetupType', 'shDisableReadyMemo', 'shAlwaysShowComponentsList', 'shFlatComponentsList', 'shShowComponentSizes', 'shUsePreviousTasks', 'shDisableReadyPage', 'shAlwaysShowDirOnReadyPage', 'shAlwaysShowGroupOnReadyPage', 'shAllowUNCPath', 'shUserInfoPage', 'shUsePreviousUserInfo', 'shUninstallRestartComputer', 'shRestartIfNeededByRun', 'shShowTasksTreeLines', 'shAllowCancelDuringInstall', 'shWizardImageStretch', 'shAppendDefaultDirName', 'shAppendDefaultGroupName', 'shEncryptionUsed', 'shChangesEnvironment', 'shShowUndisplayableLanguages', 'shSetupLogging', 'shSignedUninstaller', 'shUsePreviousLanguage', 'shDisableWelcomePage', 'shCloseApplications', 'shRestartApplications', 'shAllowNetworkDrive', 'shForceCloseApplications' ]),
	};
	return $ret;
}
sub TSetupLanguageEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		LanguageName => $self->ReadString(1),
		DialogFontName => $self->ReadString(1),
		TitleFontName => $self->ReadString(1),
		WelcomeFontName => $self->ReadString(1),
		CopyrightFontName => $self->ReadString(1),
		Data => $self->ReadString(1),
		LicenseText => $self->ReadString(1),
		InfoBeforeText => $self->ReadString(1),
		InfoAfterText => $self->ReadString(1),
		LanguageID => $self->ReadCardinal(),
		LanguageCodePage => $self->ReadCardinal(),
		DialogFontSize => $self->ReadInteger(),
		TitleFontSize => $self->ReadInteger(),
		WelcomeFontSize => $self->ReadInteger(),
		CopyrightFontSize => $self->ReadInteger(),
		RightToLeft => $self->ReadByte(),
	};
	return $ret;
}
sub TSetupCustomMessageEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		Value => $self->ReadString(1),
		LangIndex => $self->ReadInteger(),
	};
	return $ret;
}
sub TSetupPermissionEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Permissions => $self->ReadString(1),
	};
	return $ret;
}
sub TSetupTypeEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		Description => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
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
		Options => $self->ReadSet([ 'toIsCustom' ]),
		Typ => $self->ReadEnum([ 'ttUser', 'ttDefaultFull', 'ttDefaultCompact', 'ttDefaultCustom' ]),
		Size => $self->ReadInt64(),
	};
	return $ret;
}
sub TSetupComponentEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		Description => $self->ReadString(1),
		Types => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		ExtraDiskSpaceRequired => $self->ReadInt64(),
		Level => $self->ReadInteger(),
		Used => $self->ReadByte(),
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
		Options => $self->ReadSet([ 'coFixed', 'coRestart', 'coDisableNoUninstallWarning', 'coExclusive', 'coDontInheritCheck' ]),
		Size => $self->ReadInt64(),
	};
	return $ret;
}
sub TSetupTaskEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		Description => $self->ReadString(1),
		GroupDescription => $self->ReadString(1),
		Components => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		Level => $self->ReadInteger(),
		Used => $self->ReadByte(),
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
		Options => $self->ReadSet([ 'toExclusive', 'toUnchecked', 'toRestart', 'toCheckedOnce', 'toDontInheritCheck' ]),
	};
	return $ret;
}
sub TSetupDirEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		DirName => $self->ReadString(1),
		Components => $self->ReadString(1),
		Tasks => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		AfterInstall => $self->ReadString(1),
		BeforeInstall => $self->ReadString(1),
		Attribs => $self->ReadInteger(),
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
		PermissionsEntry => $self->ReadSmallInt(),
		Options => $self->ReadSet([ 'doUninsNeverUninstall', 'doDeleteAfterInstall', 'doUninsAlwaysUninstall', 'doSetNTFSCompression', 'doUnsetNTFSCompression' ]),
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
		StrongAssemblyName => $self->ReadString(1),
		Components => $self->ReadString(1),
		Tasks => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		AfterInstall => $self->ReadString(1),
		BeforeInstall => $self->ReadString(1),
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
		ExternalSize => $self->ReadInt64(),
		PermissionsEntry => $self->ReadSmallInt(),
		Options => $self->ReadSet([ 'foConfirmOverwrite', 'foUninsNeverUninstall', 'foRestartReplace', 'foDeleteAfterInstall', 'foRegisterServer', 'foRegisterTypeLib', 'foSharedFile', 'foCompareTimeStamp', 'foFontIsntTrueType', 'foSkipIfSourceDoesntExist', 'foOverwriteReadOnly', 'foOverwriteSameVersion', 'foCustomDestName', 'foOnlyIfDestFileExists', 'foNoRegError', 'foUninsRestartDelete', 'foOnlyIfDoesntExist', 'foIgnoreVersion', 'foPromptIfOlder', 'foDontCopy', 'foUninsRemoveReadOnly', 'foRecurseSubDirsExternal', 'foReplaceSameVersionIfContentsDiffer', 'foDontVerifyChecksum', 'foUninsNoSharedFilePrompt', 'foCreateAllSubDirs', 'fo32Bit', 'fo64Bit', 'foExternalSizePreset', 'foSetNTFSCompression', 'foUnsetNTFSCompression', 'foGacInstall' ]),
		FileType => $self->ReadEnum([ 'ftUserFile', 'ftUninstExe' ]),
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
		Components => $self->ReadString(1),
		Tasks => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		AfterInstall => $self->ReadString(1),
		BeforeInstall => $self->ReadString(1),
		AppUserModelID => $self->ReadString(1),
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
		HotKey => $self->ReadWord(),
		Options => $self->ReadSet([ 'ioUninsNeverUninstall', 'ioCreateOnlyIfFileExists', 'ioUseAppPaths', 'ioFolderShortcut', 'ioExcludeFromShowInNewInstall', 'ioPreventPinning' ]),
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
		Components => $self->ReadString(1),
		Tasks => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		AfterInstall => $self->ReadString(1),
		BeforeInstall => $self->ReadString(1),
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
		Components => $self->ReadString(1),
		Tasks => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		AfterInstall => $self->ReadString(1),
		BeforeInstall => $self->ReadString(1),
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
		PermissionsEntry => $self->ReadSmallInt(),
		Typ => $self->ReadEnum([ 'rtNone', 'rtString', 'rtExpandString', 'rtDWord', 'rtBinary', 'rtMultiString', 'rtQWord' ]),
		Options => $self->ReadSet([ 'roCreateValueIfDoesntExist', 'roUninsDeleteValue', 'roUninsClearValue', 'roUninsDeleteEntireKey', 'roUninsDeleteEntireKeyIfEmpty', 'roPreserveStringType', 'roDeleteKey', 'roDeleteValue', 'roNoError', 'roDontCreateKey', 'ro32Bit', 'ro64Bit' ]),
	};
	return $ret;
}
sub TSetupDeleteEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		Name => $self->ReadString(1),
		Components => $self->ReadString(1),
		Tasks => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		AfterInstall => $self->ReadString(1),
		BeforeInstall => $self->ReadString(1),
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
		StatusMsg => $self->ReadString(1),
		Verb => $self->ReadString(1),
		Description => $self->ReadString(1),
		Components => $self->ReadString(1),
		Tasks => $self->ReadString(1),
		Languages => $self->ReadString(1),
		Check => $self->ReadString(1),
		AfterInstall => $self->ReadString(1),
		BeforeInstall => $self->ReadString(1),
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
		Options => $self->ReadSet([ 'roShellExec', 'roSkipIfDoesntExist', 'roPostInstall', 'roUnchecked', 'roSkipIfSilent', 'roSkipIfNotSilent', 'roHideWizard', 'roRun32Bit', 'roRun64Bit', 'roRunAsOriginalUser' ]),
	};
	return $ret;
}
sub TSetupFileLocationEntry {
	my ($self) = @_;
	my $ret;
	$ret = {
		FirstSlice => $self->ReadInteger(),
		LastSlice => $self->ReadInteger(),
		StartOffset => $self->ReadLongInt(),
		ChunkSuboffset => $self->ReadInt64(),
		OriginalSize => $self->ReadInt64(),
		ChunkCompressedSize => $self->ReadInt64(),
		SHA1Sum => $self->TSHA1Digest(),
		SourceTimeStamp => $self->TFileTime(),
		FileVersionMS => $self->DWORD(),
		FileVersionLS => $self->DWORD(),
		Flags => $self->ReadSet([ 'foVersionInfoValid', 'foVersionInfoNotValid', 'foTimeStampInUTC', 'foIsUninstExe', 'foCallInstructionOptimized', 'foApplyTouchDateTime', 'foChunkEncrypted', 'foChunkCompressed', 'foSolidBreak', 'foSign', 'foSignOnce' ]),
	};
	return $ret;
}
1;
