#!/usr/bin/perl

package Win::Exe;

use strict;
use warnings;
use feature 'switch';
use IO::File;
use Win::Exe::Util;
use Win::Exe::DosHeader;
use Win::Exe::PeHeader;
use Win::Exe::OptionalHeader;
use Win::Exe::Section;
use Win::Exe::Table;

use Data::Dumper;

use overload (
	'""' => \&Describe,
);

sub new {
	my $class = shift;
	my ($io) = @_;
	
	my $self = { };
	
	if (ref($io)) {
		# interpret as IO object or glob
		$self->{Input} = $io;
	} else {
		# interpret as filename
		$self->{Filename} = $io;
		$self->{Input} = IO::File->new($io, '<') || die("Can't open $io");
		$self->{Input}->binmode();
	}
	
	return bless($self, $class);
}

sub DosHeader {
	my $self = shift;
	if (!$self->{DosHeader}) {
		$self->{DosHeader} = Win::Exe::DosHeader->new($self);
	}
	return $self->{DosHeader}
}

sub PeHeader {
	my $self = shift;
	if (!$self->{PeHeader}) {
		$self->IsPeExe() || die("Can't find PE header");
		$self->{PeHeader} = Win::Exe::PeHeader->new($self);
	}
	return $self->{PeHeader};
}

sub OptionalHeader {
	my $self = shift;
	if (!$self->{OptionalHeader}) {
		$self->{OptionalHeader} = Win::Exe::OptionalHeader->new($self);
	}
	return $self->{OptionalHeader};
}

sub Sections {
	my $self = shift;
	if (!$self->{Sections}) {
		$self->{Sections} = Win::Exe::Section->all($self);
	}
	return $self->{Sections};
}

sub Tables {
	my $self = shift;
	if (!$self->{Tables}) {
		$self->{Tables} = Win::Exe::Table->all($self);
	}
	return $self->{Tables};
}

sub PeOffset {
	return shift()->DosHeader()->{Lfanew};
}

sub PeSectionOffset {
	my $self = shift;
	return $self->PeOffset() + 24 + $self->PeHeader()->{SizeOfOptionalHeader};
}

sub IsPeExe {
	return shift()->PeOffset() ? 1 : 0;
}

sub FindVirtualAddress {
	my ($self, $address) = @_;
	for my $section (keys($self->Sections())) {
		my $pointer = $section->VaToPointer($address);
		if ($pointer != -1) {
			return $pointer;
		}
	}
	if ($address != 0) {
		warn("Unmappable address $address");
	}
	return -1;
}

sub FindVirtualRange {
	my ($self, $address, $size) = @_;
	for my $section (values($self->Sections())) {
		my $pointer = $section->VaToPointer($address);
		if ($pointer != -1) {
			my $end = $section->VaToPointer($address + $size);
			($end != -1) && return $pointer;
		}
	}
	if ($size != 0) {
		warn("Unmappable range ($address, $size)");
	}
	return -1;
}

sub Describe {
	my $self = shift;
	my $ret;
	if ($self->{Filename}) {
		$ret .= $self->{Filename} . ":\n";
	} else {
		print("EXE file:\n");
	}
	$ret .= $self->DosHeader()->Describe("  ");
	$ret .= $self->PeHeader()->Describe("  ");
	$ret .= $self->OptionalHeader()->Describe("  ");
	$ret .= "  Sections:\n";
	for my $section (values($self->Sections())) {
		$ret .= $section->Describe("    ");
	}
	$ret .= "  Tables:\n";
	for my $table (values($self->Tables())) {
		$ret .= $table->Describe("    ");
	}
	return $ret;
}

sub FindResource {
	return FindResourceEx(@_[0..2], 0);
}

sub FindResourceEx {
	my ($self, $type, $resid, $lang) = @_;
	my $resgroup = $self->Tables()->{ResourceTable}->GetResource($type, $resid);
	# TODO: handle language precedence rules correctly
	my $resource = $resgroup->{Directory}->{Resources}->{$lang}->{Data};
	my $offset = $self->FindVirtualRange($resource->{OffsetToData}, $resource->{Size});
	if ($offset != -1) {
		$self->{Input}->seek($offset, 0);
		$self->{Input}->read(my $buffer, $resource->{Size});
		return $buffer;
	}
	return undef;
}

1;

