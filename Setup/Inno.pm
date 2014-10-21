#!/usr/bin/perl

package Setup::Inno;

use strict;
use Switch 'Perl6';
use Fcntl;
use IO::File;
use Win::Exe;
use Win::Exe::Util;
use Setup::Inno::Interpret;
use Carp;
use Data::Dumper;

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
		$self->{Input}->seek(SetupLdrExeHeaderOffset, Fcntl::SEEK_SET) || croak("Can't seek to Inno header");
		$self->{Input}->read(my $buffer, 12) || croak("Can't get Inno header");
		my $SetupLdrExeHeader = unpackbinary($buffer, '(L3)<', 'ID', 'OffsetTableOffset', 'NotOffsetTableOffset');
		($SetupLdrExeHeader->{ID} == SetupLdrExeHeaderID) || croak("Unknown file type");
		($SetupLdrExeHeader->{OffsetTableOffset} == ~$SetupLdrExeHeader->{NotOffsetTableOffset}) || croak("Offset table pointer checksum error");
		$self->{Input}->seek($SetupLdrExeHeader->{OffsetTableOffset}, Fcntl::SEEK_SET) || croak("Can't seek to offset table");
		$self->{Input}->read($buffer, 12) || croak("Error reading offset table ID");
		$self->{Interpreter} = Setup::Inno::Interpret->new($buffer);
		$self->{Input}->read(my $buffer2, $self->{Interpreter}->OffsetTableSize() - 12) || croak("Error reading offset table");
		$self->{OffsetTable} = $self->{Interpreter}->ParseOffsetTable($buffer . $buffer2);
	} or do {
		my $exe = Win::Exe->new($self->{Input});
		my $OffsetTable = $exe->FindResource('RcData', SetupLdrOffsetTableResID) || croak("Can't find offset table resource");
		$self->{Interpreter} = Setup::Inno::Interpret->new(substr($OffsetTable, 0, 12));
		$self->{OffsetTable} = $self->{Interpreter}->ParseOffsetTable($OffsetTable);
	};
	
	#print("Offset0 " . $self->Offset0() . "\n");
	$self->{Input}->seek($self->Offset0(), Fcntl::SEEK_SET) || croak("Can't seek to setup.0 offset");
	$self->{Input}->read(my $buffer, 64) || croak("Error reading setup ID");
	$self->{TestID} = unpack('Z64', $buffer);
	$self->{Filename} = $filename;
	
	return $self;
}

sub DiskSpanning {
	return shift()->{OffsetTable}->{Offset1} == 0;
}

sub DiskInfo {
	my ($self) = @_;
	if ($self->{OffsetTable}->{Offset1} == 0) {
		if (!defined($self->{DiskInfo})) {
			$self->{DiskInfo} = $self->{Interpreter}->DiskInfo($self->{Filename}, $self->Setup0->{Header});
		}
		return $self->{DiskInfo};
	}
	return undef;
}

sub Offset0 {
	return shift()->{OffsetTable}->{Offset0};
}

sub Offset1 {
	return shift()->{OffsetTable}->{Offset1};
}

sub TotalSize {
	return shift()->{OffsetTable}->{TotalSize};
}

sub Version {
	my ($self) = @_;
	return $self->{Interpreter}->StructReader($self->{TestID}, $self->{Input})->Version;
}

sub Setup0 {
	my ($self) = @_;
	if (!$self->{Setup0}) {
		$self->{Setup0} = { };
		$self->{Input}->seek($self->Offset0() + 64, Fcntl::SEEK_SET);
		my $struct = $self->{Interpreter}->StructReader($self->{TestID}, $self->{Input});
		$self->{Setup0}->{Header} = $self->{Interpreter}->SetupHeader($struct);
		$self->{Setup0}->{Languages} = $self->{Interpreter}->SetupLanguages($struct, $self->{Setup0}->{Header}->{NumLanguageEntries});
		$self->{Setup0}->{CustomMessages} = $self->{Interpreter}->SetupCustomMessages($struct, $self->{Setup0}->{Header}->{NumCustomMessageEntries});
		$self->{Setup0}->{Permissions} = $self->{Interpreter}->SetupPermissions($struct, $self->{Setup0}->{Header}->{NumPermissionEntries});
		$self->{Setup0}->{Types} = $self->{Interpreter}->SetupTypes($struct, $self->{Setup0}->{Header}->{NumTypeEntries});
		$self->{Setup0}->{Components} = $self->{Interpreter}->SetupComponents($struct, $self->{Setup0}->{Header}->{NumComponentEntries});
		$self->{Setup0}->{Tasks} = $self->{Interpreter}->SetupTasks($struct, $self->{Setup0}->{Header}->{NumTaskEntries});
		$self->{Setup0}->{Dirs} = $self->{Interpreter}->SetupDirs($struct, $self->{Setup0}->{Header}->{NumDirEntries});
		$self->{Setup0}->{Files} = $self->{Interpreter}->SetupFiles($struct, $self->{Setup0}->{Header}->{NumFileEntries});
		$self->{Setup0}->{Icons} = $self->{Interpreter}->SetupIcons($struct, $self->{Setup0}->{Header}->{NumIconEntries});
		$self->{Setup0}->{IniEntries} = $self->{Interpreter}->SetupIniEntries($struct, $self->{Setup0}->{Header}->{NumIniEntries});
		$self->{Setup0}->{RegistryEntries} = $self->{Interpreter}->SetupRegistryEntries($struct, $self->{Setup0}->{Header}->{NumRegistryEntries});
		$self->{Setup0}->{InstallDelete} = $self->{Interpreter}->SetupDelete($struct, $self->{Setup0}->{Header}->{NumInstallDeleteEntries});
		$self->{Setup0}->{UninstallDelete} = $self->{Interpreter}->SetupDelete($struct, $self->{Setup0}->{Header}->{NumUninstallDeleteEntries});
		$self->{Setup0}->{Run} = $self->{Interpreter}->SetupRun($struct, $self->{Setup0}->{Header}->{NumRunEntries});
		$self->{Setup0}->{UninstallRun} = $self->{Interpreter}->SetupRun($struct, $self->{Setup0}->{Header}->{NumUninstallRunEntries});
		$self->{Setup0}->{Binaries} = $self->{Interpreter}->SetupBinaries($struct, $self->{Interpreter}->Compression1($self->{Setup0}->{Header}));
		# Get the current location so we can seek to the locations list later.
		# It's stored in its own LZMA stream.
		$self->{Setup0}->{OffsetLocations} = $self->{Input}->tell();
		#printf("Locations offset: 0x%08x\n", $self->{Setup0}->{OffsetLocations});
	}
	return $self->{Setup0};
}

sub FileLocations {
	my ($self) = @_;
	if (!$self->{FileLocations}) {
		my $setup0 = $self->Setup0();
		$self->{Input}->seek($setup0->{OffsetLocations}, Fcntl::SEEK_SET);
		my $struct = $self->{Interpreter}->StructReader($self->{TestID}, $self->{Input});
		#while (1) { $self->{Input}->seek(0x01000000, Fcntl::SEEK_SET); }
		$self->{FileLocations} = $self->{Interpreter}->SetupFileLocations($struct, $setup0->{Header}->{NumFileLocationEntries});
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
	($index < 0) && croak("Negative file index");
	my $setup0 = $self->Setup0();
	my $locations = $self->FileLocations();
	my $file = $self->{Setup0}->{Files}->[$index];
	my $location = $locations->[$file->{LocationEntry}];
	#return { File => $file, Location => $location };
	my $type;
	my $name;
	given ($file->{FileType}) {
		when (/UserFile/i) {
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
		when (/UninstExe/i) {
			$type = 'UninstExe';
			# TODO: Find out if the name of the uninstaller exe is found somewhere else
			if ($file->{DestName}) {
				$name = $file->{DestName};
			} else {
				$name = DefaultUninstallExeName;
			}
		}
		when (/RegSvrExe/i) {
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
		Compressed => $location->{Flags}->{ChunkCompressed} || $location->{Flags}->{foChunkCompressed},
		Encrypted => $location->{Flags}->{ChunkEncrypted} || $location->{Flags}->{foChunkEncrypted},
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
	if ($self->DiskSpanning()) {
		#print Dumper($self->DiskInfo);
		#print Dumper($location);
		my $info = $self->DiskInfo->[$location->{FirstSlice}];
		return $self->{Interpreter}->ReadFile($info->{Input}, $setup0->{Header}, $location, 0, $password);
	} else {
		#$self->{Input}->seek($self->Offset1(), Fcntl::SEEK_SET);
		return $self->{Interpreter}->ReadFile($self->{Input}, $setup0->{Header}, $location, $self->Offset1(), $password);
	}
}

1;

