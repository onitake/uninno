package Setup::Inno::Struct5500u;
use strict;
use base 'Setup::Inno::Struct5309';
sub SetupHeader { my ($self, $reader) = @_; return $self->TSetupHeader($reader); }
sub SetupLanguages { my ($self, $reader, $count) = @_; return [ map { $self->TSetupLanguageEntry($reader) } 0..$count-1 ]; }
sub SetupCustomMessages { my ($self, $reader, $count) = @_; return [ map { $self->TSetupCustomMessageEntry($reader) } 0..$count-1 ]; }
sub SetupPermissions { my ($self, $reader, $count) = @_; return [ map { $self->TSetupPermissionEntry($reader) } 0..$count-1 ]; }
sub SetupTypes { my ($self, $reader, $count) = @_; return [ map { $self->TSetupTypeEntry($reader) } 0..$count-1 ]; }
sub SetupComponents { my ($self, $reader, $count) = @_; return [ map { $self->TSetupComponentEntry($reader) } 0..$count-1 ]; }
sub SetupTasks { my ($self, $reader, $count) = @_; return [ map { $self->TSetupTaskEntry($reader) } 0..$count-1 ]; }
sub SetupDirs { my ($self, $reader, $count) = @_; return [ map { $self->TSetupDirEntry($reader) } 0..$count-1 ]; }
sub SetupFiles { my ($self, $reader, $count) = @_; return [ map { $self->TSetupFileEntry($reader) } 0..$count-1 ]; }
sub SetupIcons { my ($self, $reader, $count) = @_; return [ map { $self->TSetupIconEntry($reader) } 0..$count-1 ]; }
sub SetupIniEntries { my ($self, $reader, $count) = @_; return [ map { $self->TSetupIniEntry($reader) } 0..$count-1 ]; }
sub SetupRegistryEntries { my ($self, $reader, $count) = @_; return [ map { $self->TSetupRegistryEntry($reader) } 0..$count-1 ]; }
sub SetupDelete { my ($self, $reader, $count) = @_; return [ map { $self->TSetupDeleteEntry($reader) } 0..$count-1 ]; }
sub SetupRun { my ($self, $reader, $count) = @_; return [ map { $self->TSetupRunEntry($reader) } 0..$count-1 ]; }
sub SetupFileLocations { my ($self, $reader, $count) = @_; return [ map { $self->TSetupFileLocationEntry($reader) } 0..$count-1 ]; }
sub TFileTime {
	my ($self, $reader) = @_;
	my $tlow = $reader->ReadLongWord();
	my $thigh = $reader->ReadLongWord();
	my $hnsecs = $tlow | ($thigh << 32);
	my $secs = int($hnsecs / 10000000);
	my $nsecs = ($hnsecs - $secs * 10000000) * 100;
	return DateTime->new(year => 1601, month => 1, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0)->add(seconds => $secs, nanoseconds => $nsecs);
}
sub HKEY {
	my ($self, $reader) = @_;
	return $reader->ReadLongWord();
}
sub DWORD {
	my ($self, $reader) = @_;
	return $reader->ReadLongWord();
}
sub TSHA1Digest {
	my ($self, $reader) = @_;
	return $reader->ReadByteArray(20);
}
sub TMD5Digest {
	my ($self, $reader) = @_;
	return $reader->ReadByteArray(16);
}
sub TSetupHeader {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		AppName => $reader->ReadString(2),
		AppVerName => $reader->ReadString(2),
		AppId => $reader->ReadString(2),
		AppCopyright => $reader->ReadString(2),
		AppPublisher => $reader->ReadString(2),
		AppPublisherURL => $reader->ReadString(2),
		AppSupportPhone => $reader->ReadString(2),
		AppSupportURL => $reader->ReadString(2),
		AppUpdatesURL => $reader->ReadString(2),
		AppVersion => $reader->ReadString(2),
		DefaultDirName => $reader->ReadString(2),
		DefaultGroupName => $reader->ReadString(2),
		BaseFilename => $reader->ReadString(2),
		UninstallFilesDir => $reader->ReadString(2),
		UninstallDisplayName => $reader->ReadString(2),
		UninstallDisplayIcon => $reader->ReadString(2),
		AppMutex => $reader->ReadString(2),
		DefaultUserInfoName => $reader->ReadString(2),
		DefaultUserInfoOrg => $reader->ReadString(2),
		DefaultUserInfoSerial => $reader->ReadString(2),
		AppReadmeFile => $reader->ReadString(2),
		AppContact => $reader->ReadString(2),
		AppComments => $reader->ReadString(2),
		AppModifyPath => $reader->ReadString(2),
		CreateUninstallRegKey => $reader->ReadString(2),
		Uninstallable => $reader->ReadString(2),
		CloseApplicationsFilter => $reader->ReadString(2),
		LicenseText => $reader->ReadString(1),
		InfoBeforeText => $reader->ReadString(1),
		InfoAfterText => $reader->ReadString(1),
		CompiledCodeText => $reader->ReadString(1),
		NumLanguageEntries => $reader->ReadInteger(),
		NumCustomMessageEntries => $reader->ReadInteger(),
		NumPermissionEntries => $reader->ReadInteger(),
		NumTypeEntries => $reader->ReadInteger(),
		NumComponentEntries => $reader->ReadInteger(),
		NumTaskEntries => $reader->ReadInteger(),
		NumDirEntries => $reader->ReadInteger(),
		NumFileEntries => $reader->ReadInteger(),
		NumFileLocationEntries => $reader->ReadInteger(),
		NumIconEntries => $reader->ReadInteger(),
		NumIniEntries => $reader->ReadInteger(),
		NumRegistryEntries => $reader->ReadInteger(),
		NumInstallDeleteEntries => $reader->ReadInteger(),
		NumUninstallDeleteEntries => $reader->ReadInteger(),
		NumRunEntries => $reader->ReadInteger(),
		NumUninstallRunEntries => $reader->ReadInteger(),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		BackColor => $reader->ReadLongInt(),
		BackColor2 => $reader->ReadLongInt(),
		WizardImageBackColor => $reader->ReadLongInt(),
		PasswordHash => $self->TSHA1Digest($reader),
		PasswordSalt => [ map({ $reader->ReadByte() } (0..7)) ],
		ExtraDiskSpaceRequired => $reader->ReadInt64(),
		SlicesPerDisk => $reader->ReadInteger(),
		UninstallLogMode => $reader->ReadEnum([ 'lmAppend', 'lmNew', 'lmOverwrite' ]),
		DirExistsWarning => $reader->ReadEnum([ 'ddAuto', 'ddNo', 'ddYes' ]),
		PrivilegesRequired => $reader->ReadEnum([ 'prNone', 'prPowerUser', 'prAdmin', 'prLowest' ]),
		ShowLanguageDialog => $reader->ReadEnum([ 'slYes', 'slNo', 'slAuto' ]),
		LanguageDetectionMethod => $reader->ReadEnum([ 'ldUILanguage', 'ldLocale', 'ldNone' ]),
		CompressMethod => $reader->ReadEnum([ 'cmStored', 'cmZip', 'cmBzip', 'cmLZMA', 'cmLZMA2' ]),
		ArchitecturesAllowed => $reader->ReadSet([ 'paUnknown', 'paX86', 'paX64', 'paIA64' ]),
		ArchitecturesInstallIn64BitMode => $reader->ReadSet([ 'paUnknown', 'paX86', 'paX64', 'paIA64' ]),
		DisableDirPage => $reader->ReadEnum([ 'dpAuto', 'dpNo', 'dpYes' ]),
		DisableProgramGroupPage => $reader->ReadEnum([ 'dpAuto', 'dpNo', 'dpYes' ]),
		UninstallDisplaySize => $reader->ReadInt64(),
		Options => $reader->ReadSet([ 'shDisableStartupPrompt', 'shCreateAppDir', 'shAllowNoIcons', 'shAlwaysRestart', 'shAlwaysUsePersonalGroup', 'shWindowVisible', 'shWindowShowCaption', 'shWindowResizable', 'shWindowStartMaximized', 'shEnableDirDoesntExistWarning', 'shPassword', 'shAllowRootDirectory', 'shDisableFinishedPage', 'shChangesAssociations', 'shUsePreviousAppDir', 'shBackColorHorizontal', 'shUsePreviousGroup', 'shUpdateUninstallLogAppName', 'shUsePreviousSetupType', 'shDisableReadyMemo', 'shAlwaysShowComponentsList', 'shFlatComponentsList', 'shShowComponentSizes', 'shUsePreviousTasks', 'shDisableReadyPage', 'shAlwaysShowDirOnReadyPage', 'shAlwaysShowGroupOnReadyPage', 'shAllowUNCPath', 'shUserInfoPage', 'shUsePreviousUserInfo', 'shUninstallRestartComputer', 'shRestartIfNeededByRun', 'shShowTasksTreeLines', 'shAllowCancelDuringInstall', 'shWizardImageStretch', 'shAppendDefaultDirName', 'shAppendDefaultGroupName', 'shEncryptionUsed', 'shChangesEnvironment', 'shSetupLogging', 'shSignedUninstaller', 'shUsePreviousLanguage', 'shDisableWelcomePage', 'shCloseApplications', 'shRestartApplications', 'shAllowNetworkDrive' ]),
	};
	return $ret;
}
sub TSetupLanguageEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Name => $reader->ReadString(2),
		LanguageName => $reader->ReadString(2),
		DialogFontName => $reader->ReadString(2),
		TitleFontName => $reader->ReadString(2),
		WelcomeFontName => $reader->ReadString(2),
		CopyrightFontName => $reader->ReadString(2),
		Data => $reader->ReadString(1),
		LicenseText => $reader->ReadString(1),
		InfoBeforeText => $reader->ReadString(1),
		InfoAfterText => $reader->ReadString(1),
		LanguageID => $reader->ReadCardinal(),
		DialogFontSize => $reader->ReadInteger(),
		TitleFontSize => $reader->ReadInteger(),
		WelcomeFontSize => $reader->ReadInteger(),
		CopyrightFontSize => $reader->ReadInteger(),
		RightToLeft => $reader->ReadByte(),
	};
	return $ret;
}
sub TSetupCustomMessageEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Name => $reader->ReadString(2),
		Value => $reader->ReadString(2),
		LangIndex => $reader->ReadInteger(),
	};
	return $ret;
}
sub TSetupPermissionEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Permissions => $reader->ReadString(1),
	};
	return $ret;
}
sub TSetupTypeEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Name => $reader->ReadString(2),
		Description => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		Options => $reader->ReadSet([ 'toIsCustom' ]),
		Typ => $reader->ReadEnum([ 'ttUser', 'ttDefaultFull', 'ttDefaultCompact', 'ttDefaultCustom' ]),
		Size => $reader->ReadInt64(),
	};
	return $ret;
}
sub TSetupComponentEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Name => $reader->ReadString(2),
		Description => $reader->ReadString(2),
		Types => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		ExtraDiskSpaceRequired => $reader->ReadInt64(),
		Level => $reader->ReadInteger(),
		Used => $reader->ReadByte(),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		Options => $reader->ReadSet([ 'coFixed', 'coRestart', 'coDisableNoUninstallWarning', 'coExclusive', 'coDontInheritCheck' ]),
		Size => $reader->ReadInt64(),
	};
	return $ret;
}
sub TSetupTaskEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Name => $reader->ReadString(2),
		Description => $reader->ReadString(2),
		GroupDescription => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		Level => $reader->ReadInteger(),
		Used => $reader->ReadByte(),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		Options => $reader->ReadSet([ 'toExclusive', 'toUnchecked', 'toRestart', 'toCheckedOnce', 'toDontInheritCheck' ]),
	};
	return $ret;
}
sub TSetupDirEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		DirName => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Tasks => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		AfterInstall => $reader->ReadString(2),
		BeforeInstall => $reader->ReadString(2),
		Attribs => $reader->ReadInteger(),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		PermissionsEntry => $reader->ReadSmallInt(),
		Options => $reader->ReadSet([ 'doUninsNeverUninstall', 'doDeleteAfterInstall', 'doUninsAlwaysUninstall', 'doSetNTFSCompression', 'doUnsetNTFSCompression' ]),
	};
	return $ret;
}
sub TSetupFileEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		SourceFilename => $reader->ReadString(2),
		DestName => $reader->ReadString(2),
		InstallFontName => $reader->ReadString(2),
		StrongAssemblyName => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Tasks => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		AfterInstall => $reader->ReadString(2),
		BeforeInstall => $reader->ReadString(2),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		LocationEntry => $reader->ReadInteger(),
		Attribs => $reader->ReadInteger(),
		ExternalSize => $reader->ReadInt64(),
		PermissionsEntry => $reader->ReadSmallInt(),
		Options => $reader->ReadSet([ 'foConfirmOverwrite', 'foUninsNeverUninstall', 'foRestartReplace', 'foDeleteAfterInstall', 'foRegisterServer', 'foRegisterTypeLib', 'foSharedFile', 'foCompareTimeStamp', 'foFontIsntTrueType', 'foSkipIfSourceDoesntExist', 'foOverwriteReadOnly', 'foOverwriteSameVersion', 'foCustomDestName', 'foOnlyIfDestFileExists', 'foNoRegError', 'foUninsRestartDelete', 'foOnlyIfDoesntExist', 'foIgnoreVersion', 'foPromptIfOlder', 'foDontCopy', 'foUninsRemoveReadOnly', 'foRecurseSubDirsExternal', 'foReplaceSameVersionIfContentsDiffer', 'foDontVerifyChecksum', 'foUninsNoSharedFilePrompt', 'foCreateAllSubDirs', 'fo32Bit', 'fo64Bit', 'foExternalSizePreset', 'foSetNTFSCompression', 'foUnsetNTFSCompression', 'foGacInstall' ]),
		FileType => $reader->ReadEnum([ 'ftUserFile', 'ftUninstExe' ]),
	};
	return $ret;
}
sub TSetupIconEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		IconName => $reader->ReadString(2),
		Filename => $reader->ReadString(2),
		Parameters => $reader->ReadString(2),
		WorkingDir => $reader->ReadString(2),
		IconFilename => $reader->ReadString(2),
		Comment => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Tasks => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		AfterInstall => $reader->ReadString(2),
		BeforeInstall => $reader->ReadString(2),
		AppUserModelID => $reader->ReadString(2),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		IconIndex => $reader->ReadInteger(),
		ShowCmd => $reader->ReadInteger(),
		CloseOnExit => $reader->ReadEnum([ 'icNoSetting', 'icYes', 'icNo' ]),
		HotKey => $reader->ReadWord(),
		Options => $reader->ReadSet([ 'ioUninsNeverUninstall', 'ioCreateOnlyIfFileExists', 'ioUseAppPaths', 'ioFolderShortcut', 'ioExcludeFromShowInNewInstall', 'ioPreventPinning' ]),
	};
	return $ret;
}
sub TSetupIniEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Filename => $reader->ReadString(2),
		Section => $reader->ReadString(2),
		Entry => $reader->ReadString(2),
		Value => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Tasks => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		AfterInstall => $reader->ReadString(2),
		BeforeInstall => $reader->ReadString(2),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		Options => $reader->ReadSet([ 'ioCreateKeyIfDoesntExist', 'ioUninsDeleteEntry', 'ioUninsDeleteEntireSection', 'ioUninsDeleteSectionIfEmpty', 'ioHasValue' ]),
	};
	return $ret;
}
sub TSetupRegistryEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Subkey => $reader->ReadString(2),
		ValueName => $reader->ReadString(2),
		ValueData => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Tasks => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		AfterInstall => $reader->ReadString(2),
		BeforeInstall => $reader->ReadString(2),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		RootKey => $self->HKEY($reader),
		PermissionsEntry => $reader->ReadSmallInt(),
		Typ => $reader->ReadEnum([ 'rtNone', 'rtString', 'rtExpandString', 'rtDWord', 'rtBinary', 'rtMultiString', 'rtQWord' ]),
		Options => $reader->ReadSet([ 'roCreateValueIfDoesntExist', 'roUninsDeleteValue', 'roUninsClearValue', 'roUninsDeleteEntireKey', 'roUninsDeleteEntireKeyIfEmpty', 'roPreserveStringType', 'roDeleteKey', 'roDeleteValue', 'roNoError', 'roDontCreateKey', 'ro32Bit', 'ro64Bit' ]),
	};
	return $ret;
}
sub TSetupDeleteEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Name => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Tasks => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		AfterInstall => $reader->ReadString(2),
		BeforeInstall => $reader->ReadString(2),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		DeleteType => $reader->ReadEnum([ 'dfFiles', 'dfFilesAndOrSubdirs', 'dfDirIfEmpty' ]),
	};
	return $ret;
}
sub TSetupRunEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		Name => $reader->ReadString(2),
		Parameters => $reader->ReadString(2),
		WorkingDir => $reader->ReadString(2),
		RunOnceId => $reader->ReadString(2),
		StatusMsg => $reader->ReadString(2),
		Verb => $reader->ReadString(2),
		Description => $reader->ReadString(2),
		Components => $reader->ReadString(2),
		Tasks => $reader->ReadString(2),
		Languages => $reader->ReadString(2),
		Check => $reader->ReadString(2),
		AfterInstall => $reader->ReadString(2),
		BeforeInstall => $reader->ReadString(2),
		MinVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		OnlyBelowVersion => {
			WinVersion => $reader->ReadCardinal(),
			NTVersion => $reader->ReadCardinal(),
			NTServicePack => $reader->ReadWord(),
		},
		ShowCmd => $reader->ReadInteger(),
		Wait => $reader->ReadEnum([ 'rwWaitUntilTerminated', 'rwNoWait', 'rwWaitUntilIdle' ]),
		Options => $reader->ReadSet([ 'roShellExec', 'roSkipIfDoesntExist', 'roPostInstall', 'roUnchecked', 'roSkipIfSilent', 'roSkipIfNotSilent', 'roHideWizard', 'roRun32Bit', 'roRun64Bit', 'roRunAsOriginalUser' ]),
	};
	return $ret;
}
sub TSetupFileLocationEntry {
	my ($self, $reader) = @_;
	my $ret;
	$ret = {
		FirstSlice => $reader->ReadInteger(),
		LastSlice => $reader->ReadInteger(),
		StartOffset => $reader->ReadLongInt(),
		ChunkSuboffset => $reader->ReadInt64(),
		OriginalSize => $reader->ReadInt64(),
		ChunkCompressedSize => $reader->ReadInt64(),
		SHA1Sum => $self->TSHA1Digest($reader),
		TimeStamp => $self->TFileTime($reader),
		FileVersionMS => $self->DWORD($reader),
		FileVersionLS => $self->DWORD($reader),
		Flags => $reader->ReadSet([ 'foVersionInfoValid', 'foVersionInfoNotValid', 'foTimeStampInUTC', 'foIsUninstExe', 'foCallInstructionOptimized', 'foTouch', 'foChunkEncrypted', 'foChunkCompressed', 'foSolidBreak' ]),
	};
	return $ret;
}
1;
