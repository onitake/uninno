#!/usr/bin/perl

package Setup::Inno::Struct2008;

use strict;
use base qw(Setup::Inno::Struct);
use feature 'switch';
use Fcntl;
use Digest;
use IO::Uncompress::AnyInflate;
use IO::Uncompress::Bunzip2;
use Win::Exe::Util;

=comment
  TSetupLdrOffsetTable = packed record
    ID: array[1..12] of Char;
    TotalSize,
    OffsetEXE, CompressedSizeEXE, UncompressedSizeEXE, AdlerEXE,
    OffsetMsg, Offset0, Offset1: Longint;
  end;
=cut
sub OffsetTableSize {
	return 44;
}

sub ParseOffsetTable {
	my ($self, $data) = @_;
	(length($data) >= $self->OffsetTableSize()) || die("Invalid offset table size");
	my $ofstable = unpackbinary($data, '(a12L8)<', 'ID', 'TotalSize', 'OffsetEXE', 'CompressedSizeEXE', 'UncompressedSizeEXE', 'AdlerEXE', 'OffsetMsg', 'Offset0', 'Offset1');
	return $ofstable;
}

sub CheckFile {
	my ($self, $data, $checksum) = @_;
	my $digest = Digest->new('Adler-32');
	$digest->add($data);
	return $digest->digest() eq $checksum;
}

sub Compression1 {
	my ($self, $header) = @_;
	if (!defined($header->{CompressMethod}) || $header->{CompressMethod} eq 'Stored' || $header->{CompressMethod} eq 0) {
		return undef;
	}
	return $header->{CompressMethod};
}

# ZlibBlockReader4008
sub FieldReader {
	my ($self, $reader) = @_;
	my $creader = IO::Uncompress::AnyInflate->new($reader, Transparent => 0) || die("Can't create zlib decompressor");
	my $freader = Setup::Inno::FieldReader->new($creader) || die("Can't create field reader");
	return $freader;
}

=comment
procedure CreateFileExtractor;
const
  DecompClasses: array[TSetupCompressMethod] of TCustomDecompressorClass =
    (TStoredDecompressor, TZDecompressor, TBZDecompressor, TLZMA1Decompressor, TLZMA2Decompressor);
begin
  if (Ver>=2008) and (Ver<=4000) then FFileExtractor := TFileExtractor4000.Create(TZDecompressor)
  else FFileExtractor := TFileExtractor.Create(DecompClasses[SetupHeader.CompressMethod]);
  Password := FixPasswordEncoding(Password);  // For proper Unicode/Ansi support
  if SetupHeader.EncryptionUsed and (Password<>'') and not TestPassword(Password) then
    writeln('Warning: incorrect password');
  FFileExtractor.CryptKey:=Password;
end;

See Extract4000.pas
=cut
sub ReadFile {
	my ($self, $input, $header, $location, $password) = @_;
	
	$input->seek($location->{StartOffset}, Fcntl::SEEK_CUR);

	my $reader;
	if ($location->{Flags}->{ChunkCompressed}) {
		given ($header->{CompressMethod}) {
			when ('Zip') {
				$reader = IO::Uncompress::AnyInflate->new($input, Transparent => 0) || die("Can't create zlib reader");
			}
			when ('Bzip') {
				$reader = IO::Uncompress::Bunzip2->new($input, Transparent => 0) || die("Can't create bzip2 reader");
			}
			default {
				# Plain reader for stored mode
				$reader = $input;
			}
		}
	} else {
		$reader = $input;
	}
	
	($reader->read(my $buffer, $location->{OriginalSize}) >= $location->{OriginalSize}) || die("Can't uncompress file");
	
	($self->CheckFile($buffer, $location->{Checksum})) || die("Invalid file checksum");
	
	return $buffer;
}


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
    shDisableAppendDir, shPassword, shAllowRootDirectory,
    shDisableFinishedPage, shAdminPrivilegesRequired,
    shAlwaysCreateUninstallIcon,
    shChangesAssociations, shCreateUninstallRegKey, shUsePreviousAppDir,
    shBackColorHorizontal, shUsePreviousGroup, shUpdateUninstallLogAppName,
    shUsePreviousSetupType, shDisableReadyMemo, shAlwaysShowComponentsList,
    shFlatComponentsList, shShowComponentSizes, shUsePreviousTasks,
    shDisableReadyPage, shAlwaysShowDirOnReadyPage, shAlwaysShowGroupOnReadyPage);
  TSetupHeader = packed record
    AppName, AppVerName, AppId, AppCopyright, AppPublisher, AppPublisherURL,
      AppSupportURL, AppUpdatesURL, AppVersion, DefaultDirName,
      DefaultGroupName, UninstallIconName, BaseFilename, LicenseText,
      InfoBeforeText, InfoAfterText, UninstallFilesDir, UninstallDisplayName,
      UninstallDisplayIcon, AppMutex: String;
    LeadBytes: set of Char; 
    NumTypeEntries, NumComponentEntries, NumTaskEntries: Integer;
    NumDirEntries, NumFileEntries, NumFileLocationEntries, NumIconEntries,
      NumIniEntries, NumRegistryEntries, NumInstallDeleteEntries,
      NumUninstallDeleteEntries, NumRunEntries, NumUninstallRunEntries: Integer;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    BackColor, BackColor2, WizardImageBackColor: Longint;
    WizardSmallImageBackColor: Longint;
    Password: Longint;
    ExtraDiskSpaceRequired: Longint;
    InstallMode: (imNormal, imSilent, imVerySilent);
    UninstallLogMode: (lmAppend, lmNew, lmOverwrite);
    UninstallStyle: (usClassic, usModern);
    DirExistsWarning: (ddAuto, ddNo, ddYes);
    Options: set of TSetupHeaderOption;
  end;
=cut
sub SetupHeader {
	my ($self, $reader) = @_;
	my $ret = { };
	my @strings = ('AppName', 'AppVerName', 'AppId', 'AppCopyright', 'AppPublisher', 'AppPublisherURL', 'AppSupportURL', 'AppUpdatesURL', 'AppVersion', 'DefaultDirName', 'DefaultGroupName', 'UninstallIconName', 'BaseFilename', 'LicenseText', 'InfoBeforeText', 'InfoAfterText', 'UninstallFilesDir', 'UninstallDisplayName', 'UninstallDisplayIcon', 'AppMutex');
	for my $string (@strings) {
		$ret->{$string} = $reader->ReadString();
	}
	$ret->{LeadBytes} = $reader->ReadSet(256);
	my @integers = ('NumTypeEntries', 'NumComponentEntries', 'NumTaskEntries', 'NumDirEntries', 'NumFileEntries', 'NumFileLocationEntries', 'NumIconEntries', 'NumIniEntries', 'NumRegistryEntries', 'NumInstallDeleteEntries', 'NumUninstallDeleteEntries', 'NumRunEntries', 'NumUninstallRunEntries');
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
	$ret->{ExtraDiskSpaceRequired} = $reader->ReadLongInt();
	$ret->{InstallMode} = $reader->ReadEnum([ 'Normal', 'Silent', 'VerySilent' ]);
	$ret->{UninstallLogMode} = $reader->ReadEnum([ 'Append', 'New', 'Overwrite' ]);
	$ret->{UninstallStyle} = $reader->ReadEnum([ 'Classic', 'Modern' ]);
	$ret->{DirExistsWarning} = $reader->ReadEnum([ 'Auto', 'No', 'Yes' ]);
	$ret->{Options} = $reader->ReadSet([ 'DisableStartupPrompt', 'Uninstallable', 'CreateAppDir', 'DisableDirPage', 'DisableProgramGroupPage', 'AllowNoIcons', 'AlwaysRestart', 'AlwaysUsePersonalGroup', 'WindowVisible', 'WindowShowCaption', 'WindowResizable', 'WindowStartMaximized', 'EnableDirDoesntExistWarning', 'DisableAppendDir', 'Password', 'AllowRootDirectory', 'DisableFinishedPage', 'AdminPrivilegesRequired', 'AlwaysCreateUninstallIcon', 'ChangesAssociations', 'CreateUninstallRegKey', 'UsePreviousAppDir', 'BackColorHorizontal', 'UsePreviousGroup', 'UpdateUninstallLogAppName', 'UsePreviousSetupType', 'DisableReadyMemo', 'AlwaysShowComponentsList', 'FlatComponentsList', 'ShowComponentSizes', 'UsePreviousTasks', 'DisableReadyPage', 'AlwaysShowDirOnReadyPage', 'AlwaysShowGroupOnReadyPage' ]);
	# Unsupported data blocks
	$ret->{NumCustomMessageEntries} = 0;
	$ret->{NumPermissionEntries} = 0;
	# Non-configurable settings
	$ret->{NumLanguageEntries} = 1;
	$ret->{CompressMethod} = 'Zlib';
	return $ret;
}

=comment
  TSetupLangOptions = packed record
    { Note: LanguageName is probably Unicode (test!) }
    LanguageName, DialogFontName, TitleFontName, WelcomeFontName,
      CopyrightFontName: String;
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
		my @strings = ('LanguageName', 'DialogFontName', 'TitleFontName', 'WelcomeFontName', 'CopyrightFontName');
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

# Unsupported
#sub SetupCustomMessages { return [ ]; }

# Unsupported
#sub SetupPermissions { return [ ]; }

=comment
  TSetupTypeOption = (toIsCustom);
  TSetupTypeOptions = set of TSetupTypeOption;
  TSetupTypeEntry = packed record
    Name, Description: String;
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
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'IsCustom' ]);
		$ret->[$i]->{Size} = $reader->ReadLongInt();
	}
	return $ret;
}

=comment
  TSetupComponentEntry = packed record
    Name, Description, Types: String;
    ExtraDiskSpaceRequired: Longint;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    Options: set of (coFixed, coRestart, coDisableNoUninstallWarning);
    { internally used: }
    Size: LongInt;
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
		$ret->{$name}->{ExtraDiskSpaceRequired} = $reader->ReadLongInt();
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{Options} = $reader->ReadSet([ 'Fixed', 'Restart', 'DisableNoUninstallWarning' ]);
		$ret->{$name}->{Size} = $reader->ReadLongInt();
	}
	return $ret;
}

=comment
  TSetupTaskEntry = packed record
    Name, Description, GroupDescription, Components: String;
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
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'Exclusive', 'Unchecked', 'Restart', 'CheckedOnce' ]);
	}
	return $ret;
}

=comment
  TSetupDirEntry = packed record
    DirName: String;
    Components, Tasks: String;
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
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'UninsNeverUninstall', 'DeleteAfterInstall', 'UninsAlwaysUninstall' ]);
	}
	return $ret;
}

=comment
  TSetupFileCopyMode = (cmNormal, cmIfDoesntExist, cmAlwaysOverwrite,
    cmAlwaysSkipIfSameOrOlder);
  TSetupFileEntry = packed record
    SourceFilename, DestName, InstallFontName: String;
    Components, Tasks: String;
    MinVersion, OnlyBelowVersion: TSetupVersionData;
    LocationEntry: Integer;
    Attribs: Integer;
    ExternalSize: Longint;
    CopyMode: TSetupFileCopyMode;
    Options: set of (foConfirmOverwrite, foUninsNeverUninstall, foRestartReplace,
      foDeleteAfterInstall, foRegisterServer, foRegisterTypeLib, foSharedFile,
      foCompareTimeStampAlso, foFontIsntTrueType,
      foSkipIfSourceDoesntExist, foOverwriteReadOnly, foOverwriteSameVersion,
      foCustomDestName, foOnlyIfDestFileExists, foNoRegError);
    FileType: (ftUserFile, ftUninstExe, ftRegSvrExe);
  end;
=cut
sub SetupFiles {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		my @strings = qw"SourceFilename DestName InstallFontName Components Tasks";
		for my $string (@strings) {
			$ret->[$i]->{$string} = $reader->ReadString();
		}
		$ret->[$i]->{MinVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->[$i]->{LocationEntry} = $reader->ReadInteger();
		$ret->[$i]->{Attribs} = $reader->ReadInteger();
		$ret->[$i]->{ExternalSize} = $reader->ReadLongInt();
		$ret->[$i]->{CopyMode} = $reader->ReadEnum([ 'Normal', 'IfDoesntExist', 'AlwaysOverwrite', 'AlwaysSkipIfSameOrOlder' ]);
		$ret->[$i]->{Options} = $reader->ReadSet([ 'ConfirmOverwrite', 'UninsNeverUninstall', 'RestartReplace', 'DeleteAfterInstall', 'RegisterServer', 'RegisterTypeLib', 'SharedFile', 'CompareTimeStampAlso', 'FontIsntTrueType', 'SkipIfSourceDoesntExist', 'OverwriteReadOnly', 'OverwriteSameVersion', 'CustomDestName', 'OnlyIfDestFileExists', 'NoRegError' ]);
		$ret->[$i]->{FileType} = $reader->ReadEnum([ 'UserFile', 'UninstExe', 'RegSvrExe' ]);
	}
	return $ret;
}

=comment
  TSetupIconCloseOnExit = (icNoSetting, icYes, icNo);
  TSetupIconEntry = packed record
    IconName, Filename, Parameters, WorkingDir, IconFilename, Comment: String;
    Components, Tasks: String;
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
		my @strings = qw"IconName Filename Parameters WorkingDir IconFilename Comment Components Tasks";
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
    Components, Tasks: String;
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
		my @strings = qw"Filename Section Entry Value Components Tasks";
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
    Components, Tasks: String;
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
		my @strings = qw"Subkey ValueName ValueData Components Tasks";
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
    Components, Tasks: String;
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
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{DeleteType} = $reader->ReadEnum([ 'Files', 'FilesAndOrSubdirs', 'DirIfEmpty' ]);
	}
	return $ret;
}

=comment
  TSetupRunEntry = packed record
    Name, Parameters, WorkingDir, RunOnceId, StatusMsg: String;
    Description, Components, Tasks: String;
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
		my @strings = qw"Parameters WorkingDir RunOnceId StatusMsg Description Components Tasks";
		for my $string (@strings) {
			$ret->{$name}->{$string} = $reader->ReadString();
		}
		$ret->{$name}->{MinVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{OnlyBelowVersion} = $self->ReadVersion($reader);
		$ret->{$name}->{ShowCmd} = $reader->ReadInteger();
		$ret->{$name}->{Wait} = $reader->ReadEnum([ 'WaitUntilTerminated', 'NoWait', 'WaitUntilIdle' ]);
		$ret->{$name}->{Options} = $reader->ReadSet([ 'ShellExec', 'SkipIfDoesntExist', 'PostInstall', 'Unchecked', 'SkipIfSilent', 'SkipIfNotSilent', 'HideWizard' ]);
	}
	return $ret;
}

=comment
typedef struct _FILETIME {
  DWORD dwLowDateTime;
  DWORD dwHighDateTime;
} FILETIME, *PFILETIME;
  TFileTime = _FILETIME;
=cut
sub ReadFileTime {
	my ($self, $reader) = @_;
	# 100-nanosecond intervals since January 1, 1601 (UTC).
	my $tlow = $reader->ReadLongWord();
	my $thigh = $reader->ReadLongWord();
	# Extract seconds so we don't exceed 64 bits
	my $hnsecs = $tlow | ($thigh << 32);

	my $secs = int($hnsecs / 10000000);
	my $nsecs = ($hnsecs - $secs * 10000000) * 100;
	return DateTime->new(year => 1601, month => 1, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0)->add(seconds => $secs, nanoseconds => $nsecs);
}

=comment
          if Ver<4000 then with pFileLocationEntry^ do begin
            Dec(FirstSlice);
            Dec(LastSlice);
          end;
  TSetupFileLocationEntry = packed record
    FirstDisk, LastDisk: Integer;
    StartOffset, OriginalSize, CompressedSize: Longint;
    Adler: Longint;
    Date: TFileTime;
    FileVersionMS, FileVersionLS: DWORD;
    Flags: set of (foVersionInfoValid, foVersionInfoNotValid);
  end;
=cut
sub SetupFileLocations {
	my ($self, $reader, $count) = @_;
	my $ret = [ ];
	for (my $i = 0; $i < $count; $i++) {
		# Disk seems to be base 1
		$ret->[$i]->{FirstSlice} = $reader->ReadInteger() - 1;
		$ret->[$i]->{LastSlice} = $reader->ReadInteger() - 1;
		$ret->[$i]->{StartOffset} = $reader->ReadLongInt();
		$ret->[$i]->{OriginalSize} = $reader->ReadLongInt();
		$ret->[$i]->{ChunkCompressedSize} = $reader->ReadLongInt();
		$ret->[$i]->{Checksum} = $reader->ReadLongInt();
		$ret->[$i]->{TimeStamp} = $self->ReadFileTime($reader);
		$ret->[$i]->{FileVersionMS} = $reader->ReadLongWord();
		$ret->[$i]->{FileVersionLS} = $reader->ReadLongWord();
		$ret->[$i]->{Flags} = $reader->ReadSet([ 'VersionInfoValid', 'VersionInfoNotValid' ]);
		# Non-configurable settings
		$ret->[$i]->{Flags}->{ChunkCompressed} = 1;
	}
	return $ret;
}

1;

