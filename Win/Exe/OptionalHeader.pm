#!/usr/bin/perl

package Win::Exe::OptionalHeader;

use strict;
use feature 'switch';

sub new {
	my ($class, $exe) = @_;
	given ($exe->PeHeader()->{Machine}) {
		when (Win::Exe::PeHeader::Machine->{I386}) {
			return Win::Exe::OptionalHeader::I386->new($exe);
		}
		when (Win::Exe::PeHeader::Machine->{Amd64}) {
			return Win::Exe::OptionalHeader::Amd64->new($exe);
		}
		default {
			die("Don't know how to interpret optional headers for architecture " . $exe->PeHeader()->MachineName());
		}
	}
	warn("No interpretation for optional headers of machine type " . $exe->PeHeader()->MachineName() . " found, ignoring");
	return bless({ }, $class);
}

package Win::Exe::OptionalHeader::I386;

use strict;
use Win::Exe::Util;

use constant {
	Subsystem => {
		Native => 1, # image doesn't require a subsystem.
		WindowsGui => 2, # image runs in the windows gui subsystem.
		WindowsCui => 3, # image runs in the windows character subsystem.
		Os2Cui => 5, # image runs in the os/2 character subsystem.
		PosixCui => 7, # image runs in the posix character subsystem.
		NativeWindows => 8, # image is a native win9x driver.
		WindowsCeGui => 9, # image runs in the windows ce subsystem.
		EfiApplication => 10,
		EfiBootServiceDriver => 11,
		EfiRuntimeDriver => 12,
		EfiRom => 13,
		Xbox => 14,
		WindowsBootApplication => 16,
	},
	Win32Characteristic => {
		DynamicBase => 0x0040, # DLL can move (ASLR)
		ForceIntegrity => 0x0080, # Code Integrity Image
		NxCompat => 0x0100, # Image is NX compatible
		NoIsolation => 0x0200, # Image understands isolation and doesn't want it
		NoSeh => 0x0400, # Image does not use SEH.  No SE handler may reside in this image
		NoBind => 0x0800, # Do not bind this image.
		WdmDriver => 0x2000, # Driver uses WDM model
		TerminalServerAware => 0x8000,
	},
	Win32Magic => 0x010B,
};

sub new {
	my $class = shift;
	my ($exe) = @_;

	my $buffer;
	$exe->{Input}->seek($exe->PeOffset() + 24, 0);
	$exe->{Input}->read($buffer, 224 - 8*16);
	my $self = unpackbinary($buffer, '(SC2L9S6L4S2L6)<', 'Magic', 'MajorLinkerVersion', 'MinorLinkerVersion', 'SizeOfCode', 'SizeOfInitializedData',
		'SizeOfUninitializedData', 'AddressOfEntryPoint', 'BaseOfCode', 'BaseOfData', 'ImageBase', 'SectionAlignment', 'FileAlignment', 'MajorOperatingSystemVersion',
		'MinorOperatingSystemVersion', 'MajorImageVersion', 'MinorImageVersion', 'MajorSubsystemVersion', 'MinorSubsystemVersion', 'Win32VersionValue', 'SizeOfImage', 'SizeOfHeaders',
		'CheckSum', 'Subsystem', 'DllCharacteristics', 'SizeOfStackReserve', 'SizeOfStackCommit', 'SizeOfHeapReserve', 'SizeOfHeapCommit',
		'LoaderFlags', 'NumberOfRvaAndSizes');
	($self->{Magic} == Win32Magic) || die("Invalid optional header magic");
	my @Keys = ('ExportTable', 'ImportTable', 'ResourceTable', 'ExceptionTable', 'SecurityTable', 'BaserelocTable', 'DebugDirectory',
		'Architecture', 'GlobalPtr', 'TlsTable', 'LoadConfigTable', 'BoundImportTable', 'IatTable', 'DelayImportTable', 'ComDescriptor');
	$self->{DataDirectory} = { };
	for (my $i = 0; $i < 16; $i++) {
		$exe->{Input}->read($buffer, 8);
		if ($i < @Keys) {
			$self->{DataDirectory}->{$Keys[$i]} = unpackbinary($buffer, '(L2)<', 'VirtualAddress', 'Size');
		}
	}
	
	return bless($self, $class);
}

sub Describe {
	my $self = shift;
	my $prefix = (@_ > 0) ? $_[0] : '';
	my $ret = "${prefix}Win32 header:\n";
	$prefix .= "  ";
	$ret .= sprintf("${prefix}Magic: 0x%04x\n", $self->{Magic});
	$ret .= sprintf("${prefix}Linker version: %u.%u\n", $self->{MajorLinkerVersion}, $self->{MinorLinkerVersion});
	$ret .= sprintf("${prefix}OS version: %u.%u\n", $self->{MajorOperatingSystemVersion}, $self->{MinorOperatingSystemVersion});
	$ret .= sprintf("${prefix}Image version: %u.%u\n", $self->{MajorImageVersion}, $self->{MinorImageVersion});
	$ret .= sprintf("${prefix}Subsystem: %s %u.%u\n", $self->SubsystemName(), $self->{MajorSubsystemVersion}, $self->{MinorSubsystemVersion});
	$ret .= sprintf("${prefix}Win32 version: %u\n", $self->{Win32VersionValue});
	$ret .= sprintf("${prefix}Entry point: 0x%08x\n", $self->{AddressOfEntryPoint});
	$ret .= sprintf("${prefix}Code base address: 0x%08x\n", $self->{BaseOfCode});
	$ret .= sprintf("${prefix}Data base address: 0x%08x\n", $self->{BaseOfData});
	$ret .= sprintf("${prefix}Image base address: 0x%08x\n", $self->{ImageBase});
	$ret .= sprintf("${prefix}Code size: %u bytes\n", $self->{SizeOfCode});
	$ret .= sprintf("${prefix}Initialized data size: %u bytes\n", $self->{SizeOfInitializedData});
	$ret .= sprintf("${prefix}Uninitialized data size: %u bytes\n", $self->{SizeOfUninitializedData});
	$ret .= sprintf("${prefix}Image size: %u bytes\n", $self->{SizeOfImage});
	$ret .= sprintf("${prefix}Header size: %u bytes\n", $self->{SizeOfHeaders});
	$ret .= sprintf("${prefix}Stack reserve size: %u bytes\n", $self->{SizeOfStackReserve});
	$ret .= sprintf("${prefix}Stack commit size: %u bytes\n", $self->{SizeOfStackCommit});
	$ret .= sprintf("${prefix}Heap reserve size: %u bytes\n", $self->{SizeOfHeapReserve});
	$ret .= sprintf("${prefix}Heap commit size: %u bytes\n", $self->{SizeOfHeapCommit});
	$ret .= sprintf("${prefix}Section alignment: %u bytes\n", $self->{SectionAlignment});
	$ret .= sprintf("${prefix}File alignment: %u bytes\n", $self->{FileAlignment});
	$ret .= sprintf("${prefix}Checksum: 0x%08x\n", $self->{CheckSum});
	$ret .= sprintf("${prefix}DLL characteristics: %s\n", join(' ', $self->Characteristics()));
	$ret .= sprintf("${prefix}Loader flags: 0x%08x\n", $self->{LoaderFlags});
	$ret .= sprintf("${prefix}RVA and size entries: %u\n", $self->{NumberOfRvaAndSizes});
	$ret .= sprintf("${prefix}Tables:\n");
	for my $key (keys($self->{DataDirectory})) {
		my $entry = $self->{DataDirectory}->{$key};
		if ($entry->{VirtualAddress} && $entry->{Size}) {
			$ret .= sprintf("${prefix}  %s: %u bytes @ 0x%08x\n", $key, $entry->{Size}, $entry->{VirtualAddress});
		}
	}
	return $ret;
}

sub Characteristics {
	my $self = shift;
	my @characteristics;
	for my $key (keys(Win32Characteristic)) {
		if ($self->{DllCharacteristics} & Win32Characteristic->{$key}) {
			push(@characteristics, $key);
		}
	}
	return @characteristics;
}

sub SubsystemName {
	my $self = shift;
	my @names = map { $self->{Subsystem} == Subsystem->{$_} ? $_ : () } keys(Subsystem);
	return $names[0];
}

sub HasTables {
	return defined(shift()->{DataDirectory});
}

1;

