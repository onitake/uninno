#!/usr/bin/perl

package Setup::Inno;

use strict;
use feature 'switch';
use Fcntl;
use IO::File;
use Win::Exe;
use Setup::Inno::Struct;

use constant {
	SetupLdrExeHeaderOffset => 0x30,
	SetupLdrExeHeaderID => 0x6F6E6E49, # 'Inno'
	SetupLdrOffsetTableResID => 11111,
	UninstallerMsgTailID => 0x67734D49,
	ExeHeaderLength => 8,
	DefaultUninstallExeName => "uninstall.exe",
	DefaultRegSvrExeName => "regsvr.exe",
};

sub new {
	my ($class, $filename) = @_;
	
	my $self = {
		Input => IO::File->new($filename, '<'),
	};
	bless($self, $class);

	eval {
		$self->{Input}->seek(SetupLdrExeHeaderOffset, Fcntl::SEEK_SET) || die("Can't seek to Inno header");
		$self->{Input}->read(my $buffer, 12) || die("Can't get Inno header");
		my $SetupLdrExeHeader = unpackbuffer($buffer, '(L3)<', 'ID', 'OffsetTableOffset', 'NotOffsetTableOffset');
		($SetupLdrExeHeader->{ID} == SetupLdrExeHeaderID) || die("Unknown file type");
		($SetupLdrExeHeader->{OffsetTableOffset} == ~$SetupLdrExeHeader->{NotOffsetTableOffset}) || die("Offset table pointer checksum error");
		$self->{Input}->seek($SetupLdrExeHeader->{OffsetTableOffset}, Fcntl::SEEK_SET) || die("Can't seek to offset table");
		$self->{Input}->read($buffer, 12) || die("Error reading offset table ID");
		$self->{Struct} = Setup::Inno::Struct->new($buffer);
		$self->{Input}->read(my $buffer2, $self->{Struct}->OffsetTableSize() - 12) || die("Error reading offset table");
		$self->{OffsetTable} = $self->{Struct}->ParseOffsetTable($buffer . $buffer2);
	} or do {
		my $exe = Win::Exe->new($self->{Input});
		my $OffsetTable = $exe->FindResource('RcData', SetupLdrOffsetTableResID);
		$self->{Struct} = Setup::Inno::Struct->new(substr($OffsetTable, 0, 12));
		$self->{OffsetTable} = $self->{Struct}->ParseOffsetTable($OffsetTable);
	};

	$self->{Input}->seek($self->Offset0(), Fcntl::SEEK_SET) || die("Can't seek to setup.0 offset");
	$self->{Input}->read(my $buffer, 64) || die("Error reading setup ID");
	my $TestID = unpack('Z64', $buffer);
	$self->{Struct}->ReBlessWithVersionString($TestID);
	
	return $self;
}

sub Offset0 {
	return shift()->{OffsetTable}->{Offset0};
}

sub Offset1 {
	return shift()->{OffsetTable}->{Offset1};
}

sub Version {
	return shift()->{Struct}->Version();
}

sub Setup0 {
	my ($self) = @_;
	if (!$self->{Setup0}) {
		$self->{Setup0} = { };
		$self->{Input}->seek($self->Offset0() + 64, Fcntl::SEEK_SET);
		my $reader = $self->{Struct}->FieldReader($self->{Input});
		$self->{Setup0}->{Header} = $self->{Struct}->SetupHeader($reader);
		$self->{Setup0}->{Languages} = $self->{Struct}->SetupLanguages($reader, $self->{Setup0}->{Header}->{NumLanguageEntries});
		$self->{Setup0}->{CustomMessages} = $self->{Struct}->SetupCustomMessages($reader, $self->{Setup0}->{Header}->{NumCustomMessageEntries});
		$self->{Setup0}->{Permissions} = $self->{Struct}->SetupPermissions($reader, $self->{Setup0}->{Header}->{NumPermissionEntries});
		$self->{Setup0}->{Types} = $self->{Struct}->SetupTypes($reader, $self->{Setup0}->{Header}->{NumTypeEntries});
		$self->{Setup0}->{Components} = $self->{Struct}->SetupComponents($reader, $self->{Setup0}->{Header}->{NumComponentEntries});
		$self->{Setup0}->{Tasks} = $self->{Struct}->SetupTasks($reader, $self->{Setup0}->{Header}->{NumTaskEntries});
		$self->{Setup0}->{Dirs} = $self->{Struct}->SetupDirs($reader, $self->{Setup0}->{Header}->{NumDirEntries});
		$self->{Setup0}->{Files} = $self->{Struct}->SetupFiles($reader, $self->{Setup0}->{Header}->{NumFileEntries});
		$self->{Setup0}->{Icons} = $self->{Struct}->SetupIcons($reader, $self->{Setup0}->{Header}->{NumIconEntries});
		$self->{Setup0}->{IniEntries} = $self->{Struct}->SetupIniEntries($reader, $self->{Setup0}->{Header}->{NumIniEntries});
		$self->{Setup0}->{RegistryEntries} = $self->{Struct}->SetupRegistryEntries($reader, $self->{Setup0}->{Header}->{NumRegistryEntries});
		$self->{Setup0}->{InstallDelete} = $self->{Struct}->SetupDelete($reader, $self->{Setup0}->{Header}->{NumInstallDeleteEntries});
		$self->{Setup0}->{UninstallDelete} = $self->{Struct}->SetupDelete($reader, $self->{Setup0}->{Header}->{NumUninstallDeleteEntries});
		$self->{Setup0}->{Run} = $self->{Struct}->SetupRun($reader, $self->{Setup0}->{Header}->{NumRunEntries});
		$self->{Setup0}->{UninstallRun} = $self->{Struct}->SetupRun($reader, $self->{Setup0}->{Header}->{NumUninstallRunEntries});
		$self->{Setup0}->{Binaries} = $self->{Struct}->SetupBinaries($reader, $self->{Struct}->Compression1($self->{Setup0}->{Header}));
		# Get the current location so we can seek to the locations list later.
		# It's stored in its own LZMA stream.
		$self->{Setup0}->{OffsetLocations} = $self->{Input}->tell();
	}
	return $self->{Setup0};
}

sub FileLocations {
	my ($self) = @_;
	if (!$self->{FileLocations}) {
		my $setup0 = $self->Setup0();
		$self->{Input}->seek($setup0->{OffsetLocations}, 0);
		my $reader = $self->{Struct}->FieldReader($self->{Input});
		$self->{FileLocations} = $self->{Struct}->SetupFileLocations($reader, $setup0->{Header}->{NumFileLocationEntries});
	}
	return $self->{FileLocations};
}

sub FileCount {
	my ($self) = @_;
	my $setup0 = $self->Setup0();
	return scalar(@{$setup0->{Files}});
}

sub FileInfo {
	my ($self, $index) = @_;
	($index < 0) && die("Negative file index");
	my $setup0 = $self->Setup0();
	my $locations = $self->FileLocations();
	my $file = $self->{Setup0}->{Files}->[$index];
	my $location = $locations->[$file->{LocationEntry}];
	#return { File => $file, Location => $location };
	my $type;
	my $name;
	given ($file->{FileType}) {
		when ('UserFile') {
			$name = $file->{DestName};
			given ($name) {
				when (/^{app}/i) {
					$type = 'App';
				}
				when (/^{tmp}/i) {
					$type = 'Tmp';
				}
				when (/^{code:[a-zA-Z0-9_|]*?}/i) {
					$type = 'Code';
				}
				when (/^{(.*?)}/i) {
					$type = $1;
				}
				default {
					$type = $name;
				}
			}
			$name =~ s/^{.*?}\\//;
			$name =~ s#\\#/#g;
		}
		when ('UninstExe') {
			$type = 'UninstExe';
			# TODO: Find out if the name of the uninstaller exe is found somewhere else
			if ($file->{DestName}) {
				$name = $file->{DestName};
			} else {
				$name = DefaultUninstallExeName;
			}
		}
		when ('RegSvrExe') {
			$type = 'RegSvrExe';
			if ($file->{DestName}) {
				$name = $file->{DestName};
			} else {
				$name = DefaultRegSvrExeName;
			}
		}
		default {
			$type = 'Unknown';
			$name = 'unknown';
		}
	}
	return {
		Size => $location->{OriginalSize},
		Date => $location->{TimeStamp},
		Compressed => $location->{Flags}->{ChunkCompressed},
		Encrypted => $location->{Flags}->{ChunkEncrypted},
		Type => $type,
		OriginalName => $file->{DestName},
		Name => $name,
	};
}

sub ReadFile {
	my ($self, $index, $password) = @_;
	my $setup0 = $self->Setup0();
	my $locations = $self->FileLocations();
	my $file = $self->{Setup0}->{Files}->[$index];
	my $location = $locations->[$file->{LocationEntry}];
	$self->{Input}->seek($self->Offset1(), Fcntl::SEEK_SET);
	return $self->{Struct}->ReadFile($self->{Input}, $setup0->{Header}, $location, $password);
}

1;

