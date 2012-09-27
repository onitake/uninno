#!/usr/bin/perl

package Win::Exe::Section;

use strict;
use Win::Exe::Util;

use constant {
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

sub all {
	my ($class, $exe) = @_;
	my $ret = { };
	for (my $i = 0; $i < $exe->PeHeader()->{NumberOfSections}; $i++) {
		my $section = $class->new($exe, $i);
		$ret->{$section->{Name}} = $section;
	}
	return $ret;
}

sub new {
	my $class = shift;
	my ($exe, $number) = @_;

	my $buffer;
	$exe->{Input}->seek($exe->PeSectionOffset() + $number * 40, 0);
	$exe->{Input}->read($buffer, 40);
	my $self = unpackbinary($buffer, '(Z8L6S2L)<', 'Name', 'VirtualSize', 'VirtualAddress', 'SizeOfRawData', 'PointerToRawData', 'PointerToRelocations', 'PointerToLinenumbers',
		'NumberOfRelocations', 'NumberOfLineNumbers', 'Characteristics');

	return bless($self, $class);
}

sub Describe {
	my $self = shift;
	my $prefix = (@_ > 0) ? $_[0] : '';
	my $ret = sprintf("${prefix}Section %s:\n", $self->{Name});
	$prefix .= "  ";
	$ret .= sprintf("${prefix}Virtual memory: %u bytes @ 0x%08x\n", $self->{VirtualSize}, $self->{VirtualAddress});
	$ret .= sprintf("${prefix}Raw data: %u bytes @ 0x%08x\n", $self->{SizeOfRawData}, $self->{PointerToRawData});
	$ret .= sprintf("${prefix}Relocations: %u @ 0x%08x\n", $self->{NumberOfRelocations}, $self->{PointerToRelocations});
	$ret .= sprintf("${prefix}Line numbers: %u @ 0x%08x\n", $self->{NumberOfLineNumbers}, $self->{PointerToLinenumbers});
	$ret .= sprintf("${prefix}Characteristics: %s\n", join(' ', $self->Characteristics()));
	return $ret;
}

sub Characteristics {
	my $self = shift;
	my @characteristics;
	for my $key (keys(SectionCharacteristic)) {
		if ($self->{Characteristics} & SectionCharacteristic->{$key}) {
			push(@characteristics, $key);
		}
	}
	return @characteristics;
}

sub VaToPointer {
	my ($self, $va) = @_;
	# VA must be mappable to the file, VM page padding is not allowed
	if ($self->{VirtualAddress} <= $va && $va <= $self->{VirtualAddress} + $self->{SizeOfRawData}) {
		return $va - $self->{VirtualAddress} + $self->{PointerToRawData};
	}
	return -1;
}

sub PointerToVa {
	my ($self, $pointer) = @_;
	if ($self->{PointerToRawData} <= $pointer && $pointer <= $self->{PointerToRawData} + $self->{SizeOfRawData}) {
		return $pointer - $self->{PointerToRawData} + $self->{VirtualAddress};
	}
	return -1;
}

1;

