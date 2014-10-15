#!/usr/bin/perl

package Win::Exe::PeHeader;

use strict;
use Switch 'Perl6';
use Win::Exe::Util;

use constant {
	PeMagic => 0x00004550, # 'PE\0\0'
	Machine => {
		I860 => 0x14d, # Intel i860
		I386 => 0x14c, # Intel I386 (same ID used for 486 and 586)
		Mips3000 => 0x162, # MIPS R3000
		Mips4000 => 0x166, # MIPS R4000
		Alpha => 0x183, # DEC Alpha AXP
		Amd64 => 0x8664,
	},
	PeCharacteristic => {
		RelocsStripped => 0x0001, # relocation info stripped from file.
		ExecutableImage => 0x0002, # file is executable  (i.e. no unresolved externel references).
		LineNumsStripped => 0x0004, # line nunbers stripped from file.
		LocalSymsStripped => 0x0008, # local symbols stripped from file.
		AggresiveWsTrim => 0x0010, # agressively trim working set
		LargeAddressAware => 0x0020, # app can handle >2gb addresses
		BytesReversedLo => 0x0080, # bytes of machine word are reversed.
		Machine32bit => 0x0100, # 32 bit word machine.
		DebugStripped => 0x0200, # debugging info stripped from file in .dbg file
		RemovableRunFromSwap => 0x0400, # if image is on removable media, copy and run from the swap file.
		NetRunFromSwap => 0x0800, # if image is on net, copy and run from the swap file.
		System => 0x1000, # system file.
		Dll => 0x2000, # file is a dll.
		UpSystem_only => 0x4000, # file should only be run on a up machine
		BytesReversedHi => 0x8000, # bytes of machine word are reversed.
	},
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
	Win64Magic => 0x020B,
	SectionCharacteristic => {
		TypeReg => 0x00000000,
		TypeDsect => 0x00000001,
		TypeNoload => 0x00000002,
		TypeGroup => 0x00000004,
		TypeNoPad => 0x00000008,
		TypeCopy => 0x00000010,
		CntCode => 0x00000020, # section contains code.
		CntInitializedData => 0x00000040, # section contains initialized data.
		CntUnitializedData => 0x00000080, # section contains uninitialized data.
		LnkOther => 0x00000100,
		LnkInfo => 0x00000200, # section contains comments or some other type of information.
		TypeOver => 0x00000400,
		LnkRemove => 0x00000800, # section contents will not become part of image.
		LnkComdat => 0x00001000, # section contents comdat.
		MemProtected => 0x00004000, # obsolete
		NoDeferSpecExc => 0x00004000, # reset speculative exceptions handling bits in the tlb entries for this section.
		Gprel => 0x00008000, # section content can be accessed relative to gp
		MemFardata => 0x00008000,
		MemSysheap => 0x00010000, # obsolete
		MemPurgeable => 0x00020000,
		Mem16bit => 0x00020000,
		MemLocked => 0x00040000,
		MemPreload => 0x00080000,
		Align1bytes => 0x00100000,
		Align2bytes => 0x00200000,
		Align4bytes => 0x00300000,
		Align8bytes => 0x00400000,
		Align16bytes => 0x00500000, # default alignment if no others are specified.
		Align32bytes => 0x00600000,
		Align64bytes => 0x00700000,
		Align128bytes => 0x00800000,
		Align256bytes => 0x00900000,
		Align512bytes => 0x00a00000,
		Align1024bytes => 0x00b00000,
		Align2048bytes => 0x00c00000,
		Align4096bytes => 0x00d00000,
		Align8192bytes => 0x00e00000,
		AlignMask => 0x00f00000,
		LnkNrelocOvfl => 0x01000000, # section contains extended relocations.
		MemDiscardable => 0x02000000, # section can be discarded.
		MemNotCached => 0x04000000, # section is not cachable.
		MemNotPaged => 0x08000000, # section is not pageable.
		MemShared => 0x10000000, # section is shareable.
		MemExecute => 0x20000000, # section is executable.
		MemRead => 0x40000000, # section is readable.
		MemWrite => 0x80000000, # section is writeable.
	},
};

sub new {
	my $class = shift;
	my ($exe) = @_;

	my $buffer;
	$exe->{Input}->seek($exe->PeOffset(), 0);
	$exe->{Input}->read($buffer, 24);
	my $self = unpackbinary($buffer, '(LS2L3S2)<', 'Signature', 'Machine', 'NumberOfSections', 'TimeDateStamp', 'PointerToSymbolTable', 'NumberOfSymbols', 'SizeOfOptionalHeader', 'Characteristics');
	($self->{Signature} == PeMagic) || die("Invalid PE magic");
	
	return bless($self, $class);
}

sub Describe {
	my $self = shift;
	my $prefix = (@_ > 0) ? $_[0] : '';
	my $ret = "${prefix}PE header:\n";
	$prefix .= "  ";
	$ret .= sprintf("${prefix}Signature: 0x%08x\n", $self->{Signature});
	$ret .= sprintf("${prefix}Machine: %s\n", $self->MachineName());
	$ret .= sprintf("${prefix}Number of sections: %u\n", $self->{NumberOfSections});
	$ret .= sprintf("${prefix}Date/time: %s\n", coffdate($self->{TimeDateStamp})->format_cldr('yyyy-MM-dd HH:mm:ss'));
	$ret .= sprintf("${prefix}Symbols: %u @ 0x%08x\n", $self->{NumberOfSymbols}, $self->{PointerToSymbolTable});
	$ret .= sprintf("${prefix}Size of optional header: %u bytes\n", $self->{SizeOfOptionalHeader});
	$ret .= sprintf("${prefix}Characteristics: %s\n", join(' ', $self->Characteristics()));
	return $ret;
}

sub MachineName {
	my $self = shift;
	given ($self->{Machine}) {
		when (Machine->{I860}) {
			return 'Intel i860';
		}
		when (Machine->{I386}) {
			return 'Intel i386';
		}
		when (Machine->{Mips3000}) {
			return 'MIPS R3000';
		}
		when (Machine->{Mips4000}) {
			return 'MIPS R4000';
		}
		when (Machine->{Alpha}) {
			return 'DEC Alpha AXP';
		}
		when (Machine->{Amd64}) {
			return 'AMD64';
		}
	}
	return sprintf("Unknown (0x%04x)", $self->{Machine});
}

sub Characteristics {
	my $self = shift;
	my @characteristics;
	for my $key (keys(%{(PeCharacteristic)})) {
		if ($self->{Characteristics} & PeCharacteristic->{$key}) {
			push(@characteristics, $key);
		}
	}
	return @characteristics;
}

1;
=comment
sub GetExeInfo {
	my ($input) = @_;
	my %ret;
	my $buffer;
	$input->seek(0, 0);
	$input->read($buffer, 64);
	$ret{ExeHeader} = unpackbinary($buffer, '(S14a8S2a20l)<', 'Magic', 'Cblp', 'Cp', 'Crlc', 'Cparhdr', 'Minalloc', 'Maxalloc', 'Ss', 'Sp', 'Csum', 'Ip', 'Cs', 'Lfarlc', 'Ovno', 'Res', 'Oemid', 'Oeminfo', 'Res2', 'Lfanew');
	($ret{ExeHeader}->{Magic} == ExeMagic) || die("Invalid EXE magic");
	$input->seek($ret{ExeHeader}->{Lfanew}, 0);
	$input->read($buffer, 24);
	$ret{PeHeader} = unpackbinary($buffer, '(LS2L3S2)<', 'Signature', 'Machine', 'NumberOfSections', 'TimeDateStamp', 'PointerToSymbolTable', 'NumberOfSymbols', 'SizeOfOptionalHeader', 'Characteristics');
	($ret{PeHeader}->{Signature} == PeMagic) || die("Invalid PE magic");
	if ($ret{PeHeader}->{Machine} == MachineI386) {
		$input->read($buffer, 224 - 8*16);
		$ret{OptionalHeader} = unpackbinary($buffer, '(SC2L9S6L4S2L6)<', 'Magic', 'MajorLinkerVersion', 'MinorLinkerVersion', 'SizeOfCode', 'SizeOfInitializedData',
			'SizeOfUninitializedData', 'AddressOfEntryPoint', 'BaseOfCode', 'BaseOfData', 'ImageBase', 'SectionAlignment', 'FileAlignment', 'MajorOperatingSystemVersion',
			'MinorOperatingSystemVersion', 'MajorImageVersion', 'MinorImageVersion', 'MajorSubsystemVersion', 'MinorSubsystemVersion', 'Win32VersionValue', 'SizeOfImage', 'SizeOfHeaders',
			'CheckSum', 'Subsystem', 'DllCharacteristics', 'SizeOfStackReserve', 'SizeOfStackCommit', 'SizeOfHeapReserve', 'SizeOfHeapCommit',
			'LoaderFlags', 'NumberOfRvaAndSizes');
		($ret{OptionalHeader}->{Magic} == Win32Magic) || die("Invalid optional header magic");
		my @Keys = ('ExportTable', 'ImportTable', 'ResourceTable', 'ExceptionTable', 'SecurityTable', 'BaserelocTable', 'DebugDirectory',
			'Architecture', 'GlobalPtr', 'TlsTable', 'LoadConfigTable', 'BoundImportTable', 'IatTable', 'DelayImportTable', 'ComDescriptor');
		$ret{DataDirectory} = { };
		for (my $i = 0; $i < 16; $i++) {
			$input->read($buffer, 8);
			if ($i < @Keys) {
				$ret{DataDirectory}->{$Keys[$i]} = unpackbinary($buffer, '(L2)<', 'VirtualAddress', 'Size');
			}
		}
	} elsif ($ret{PeHeader}->{Machine} == MachineAmd64) {
		$input->read($buffer, 240 - 8*16);
		$ret{OptionalHeader} = unpackbinary($buffer, '(SC2L5QL2S6L4S2Q4L2)<', 'Magic', 'MajorLinkerVersion', 'MinorLinkerVersion', 'SizeOfCode', 'SizeOfInitializedData',
			'SizeOfUninitializedData', 'AddressOfEntryPoint', 'BaseOfCode', 'ImageBase', 'SectionAlignment', 'FileAlignment', 'MajorOperatingSystemVersion', 'MinorOperatingSystemVersion',
			'MajorImageVersion', 'MinorImageVersion', 'MajorSubsystemVersion', 'MinorSubsystemVersion', 'Win32VersionValue', 'SizeOfImage', 'SizeOfHeaders',
			'CheckSum', 'Subsystem', 'DllCharacteristics', 'SizeOfStackReserve', 'SizeOfStackCommit', 'SizeOfHeapReserve', 'SizeOfHeapCommit',
			'LoaderFlags', 'NumberOfRvaAndSizes');
		($ret{OptionalHeader}->{Magic} == Win64Magic) || die("Invalid optional header magic");
		my @Keys = ('ExportTable', 'ImportTable', 'ResourceTable', 'ExceptionTable', 'SecurityTable', 'BaserelocTable', 'DebugDirectory',
			'Architecture', 'GlobalPtr', 'TlsTable', 'LoadConfigTable', 'BoundImportTable', 'IatTable', 'DelayImportTable', 'ComDescriptor');
		$ret{DataDirectory} = { };
		for (my $i = 0; $i < 16; $i++) {
			$input->read($buffer, 8);
			if ($i < @Keys) {
				$ret{DataDirectory}->{$Keys[$i]} = unpackbinary($buffer, '(L2)<', 'VirtualAddress', 'Size');
			}
		}
	} else {
		# Unknown architecture, skip optional header
	}
	$input->seek($ret{ExeHeader}->{Lfanew} + 24 + $ret{PeHeader}->{SizeOfOptionalHeader}, 0);
	$ret{Sections} = { };
	for (my $i = 0; $i < $ret{PeHeader}->{NumberOfSections}; $i++) {
		$input->read($buffer, 40);
		my $Section = unpackbinary($buffer, '(Z8L6S2L)<', 'Name', 'VirtualSize', 'VirtualAddress', 'SizeOfRawData', 'PointerToRawData', 'PointerToRelocations', 'PointerToLinenumbers',
			'NumberOfRelocations', 'NumberOfLineNumbers', 'Characteristics');
		$ret{Sections}->{$Section->{Name}} = $Section;
	}
	if ($ret{DataDirectory}->{ResourceTable}->{VirtualAddress}) {
		$input->seek($ret{DataDirectory}->{ResourceTable}->{VirtualAddress}, 0);
		$input->read($buffer, 16);
		my $table = unpackbinary($buffer, '(L2S4)<', 'Characteristics', 'TimeDateStamp', 'MajorVersion', 'MinorVersion', 'NumberOfNamedEntries', 'NumberOfIdEntries');
		%{$ret{DataDirectory}->{ResourceTable}} = (%{$ret{DataDirectory}->{ResourceTable}}, %{$table});
		$ret{DataDirectory}->{ResourceTable}->{NamedResources} = [ ];
		for (my $i = 0; $i < $ret{DataDirectory}->{ResourceTable}->{NumberOfNamedEntries}; $i++) {
			$input->read($buffer, 8);
			my $entry = unpackbinary($buffer, '(L2)<', 'NameOffset', 'OffsetToDirectory');
			$entry->{NameIsString} = ($entry->{NameOffset} & 0x80000000) >> 31;
			$entry->{NameOffset} = $entry->{NameOffset} & 0xefffffff;
			$entry->{DataIsDirectory} = ($entry->{OffsetToDirectory} & 0x80000000) >> 31;
			$entry->{OffsetToDirectory} = $entry->{NameOffset} & 0xefffffff;
			push(@{$ret{DataDirectory}->{ResourceTable}->{NamedResources}}, $entry);
		}
		$ret{DataDirectory}->{ResourceTable}->{Resources} = { };
	}
	return \%ret;
}
=cut

