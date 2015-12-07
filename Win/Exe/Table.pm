#!/usr/bin/perl

package Win::Exe::Table;

use strict;
use Switch 'Perl6';
use Carp;

sub all {
	my ($class, $exe) = @_;
	$exe->OptionalHeader()->HasTables() || croak("Executable type doesn't support tables");
	my $ret = { };
	for my $name (keys(%{$exe->OptionalHeader()->{DataDirectory}})) {
		$ret->{$name} = $class->new($exe, $name);
	}
	return $ret;
}

sub new {
	my ($class, $exe, $name) = @_;
	my $va = $exe->OptionalHeader()->{DataDirectory}->{$name};
	my $pointer = $exe->FindVirtualRange($va->{VirtualAddress}, $va->{Size});
	if ($pointer != -1) {
		given ($name) {
			when ('ExportTable') {
			}
			when ('ImportTable') {
			}
			when ('ResourceTable') {
				return Win::Exe::Table::Resource->new($exe, $pointer);
			}
			when ('ExceptionTable') {
			}
			when ('SecurityTable') {
			}
			when ('BaserelocTable') {
			}
			when ('DebugDirectory') {
			}
			when ('Architecture') {
			}
			when ('GlobalPtr') {
			}
			when ('TlsTable') {
			}
			when ('LoadConfigTable') {
			}
			when ('BoundImportTable') {
			}
			when ('IatTable') {
			}
			when ('DelayImportTable') {
			}
			when ('ComDescriptor') {
			}
		}
	}
	#carp("No interpretation for tables of type $name found, ignoring");
	return bless({ }, $class);
}

sub Describe {
	return "";
}

package Win::Exe::Table::Resource;

use strict;
use Encode qw(decode);
use Win::Exe::Util;
#use File::Type;
use Data::Dumper;

#our $FileType = File::Type->new();
our $ResourceTypes = {
    Accelerator => 9, # Accelerator table.
    AniCursor => 21, # Animated cursor.
    AniIcon => 22, # Animated icon.
    Bitmap => 2, # Bitmap resource.
    Cursor => 1, # Hardware-dependent cursor resource.
    Dialog => 5, # Dialog box.
    DlgInclude => 17, # Allows a resource editing tool to associate a string with an .rc file. Typically, the string is the name of the header file that provides symbolic names. The resource compiler parses the string but otherwise ignores the value. For example, 1 DLGINCLUDE "MyFile.h"
    Font => 8, # Font resource.
    FontDir => 7, # Font directory resource.
    GroupCursor => 12, # Hardware-independent cursor resource.
    GroupIcon => 14, # Hardware-independent icon resource.
    Html => 23, # HTML resource.
    Icon => 3, # Hardware-dependent icon resource.
    Manifest => 24, # Side-by-Side Assembly Manifest.
    Menu => 4, # Menu resource.
    MessageTable => 11, # Message-table entry.
    PlugPlay => 19, # Plug and Play resource.
    RcData => 10, # Application-defined resource (raw data).
    String => 6, # String-table entry.
    Version => 16, # Version resource.
    Vxd => 20, # VXD.
};

sub parsedirectory {
	my ($exe, $pointer, $offset) = @_;
	#printf("0x%08x\n", $pointer + $offset);
	my $buffer;
	$exe->{Input}->seek($pointer + $offset, 0);
	$exe->{Input}->read($buffer, 16);
	my $dir = unpackbinary($buffer, '(L2S4)<', 'Characteristics', 'TimeDateStamp', 'MajorVersion', 'MinorVersion', 'NumberOfNamedEntries', 'NumberOfIdEntries');
	$dir->{Resources} = { };
	for (my $i = 0; $i < $dir->{NumberOfNamedEntries} + $dir->{NumberOfIdEntries}; $i++) {
		$exe->{Input}->seek($pointer + $offset + 16 + $i * 8, 0);
		$exe->{Input}->read($buffer, 8);
		my $entry = unpackbinary($buffer, '(L2)<', 'Name', 'OffsetToDirectory');
		$entry->{NameIsString} = ($entry->{Name} & 0x80000000) >> 31;
		$entry->{DataIsDirectory} = ($entry->{OffsetToDirectory} & 0x80000000) >> 31;
		$entry->{OffsetToDirectory} = $entry->{OffsetToDirectory} & 0x7fffffff;
		if ($entry->{DataIsDirectory}) {
			$entry->{Directory} = parsedirectory($exe, $pointer, $entry->{OffsetToDirectory});
		} else {
			$exe->{Input}->seek($pointer + $entry->{OffsetToDirectory}, 0);
			$exe->{Input}->read($buffer, 32);
			$entry->{Data} = unpackbinary($buffer, '(L4)<', 'OffsetToData', 'Size', 'CodePage', 'Reserved');
			# Data.OffsetToData is an RVA
			#$exe->{Input}->seek($pointer + $entry->{Data}->{OffsetToData}, 0);
			#$exe->{Input}->read($entry->{Data}->{Data}, $entry->{Data}->{Size});
			#$entry->{Data}->{MimeType} = FileType->checktype_contents($entry->{Data}->{Data});
		}
		if ($entry->{NameIsString}) {
			$entry->{NameOffset} = $entry->{Name} & 0x7fffffff;
			$exe->{Input}->seek($pointer + $entry->{OffsetToDirectory}, 0);
			$exe->{Input}->read($buffer, 2);
			$entry->{NameLength} = unpack('S<', $buffer);
			$exe->{Input}->read($buffer, $entry->{NameLength});
			$entry->{Id} = decode('UTF-16LE', $buffer);
		} else {
			# is this 31bit or 16bit?
			$entry->{Id} = $entry->{Name} & 0xffff;
		}
		$dir->{Resources}->{$entry->{Id}} = $entry;
	}
	return $dir;
}

sub new {
	my ($class, $exe, $pointer) = @_;
	my $self = parsedirectory($exe, $pointer, 0);
	return bless($self, $class);
}

sub Describe {
	my $self = shift;
	my $prefix = (@_ > 0) ? $_[0] : '';
	my $ret = sprintf("${prefix}Resource table:\n");
	$prefix .= "  ";
	$ret .= sprintf("${prefix}Date/time: %s\n", coffdate($self->{TimeDateStamp})->format_cldr('yyyy-MM-dd HH:mm:ss'));
	$ret .= sprintf("${prefix}Version: %u.%u\n", $self->{MajorVersion}, $self->{MinorVersion});
	$ret .= sprintf("${prefix}Named entries: %u\n", $self->{NumberOfNamedEntries});
	$ret .= sprintf("${prefix}ID entries: %u\n", $self->{NumberOfIdEntries});
	return $ret;
}

sub GetResource {
	my ($self, $type, $resid) = @_;
	my $dir;
	if (defined($self->{Resources}->{$type})) {
		$dir = $self->{Resources}->{$type};
	} elsif (defined($ResourceTypes->{$type})) {
		$dir = $self->{Resources}->{$ResourceTypes->{$type}};
	}
	if ($dir) {
		if ($dir->{DataIsDirectory}) {
			return $dir->{Directory}->{Resources}->{$resid};
		}
	}
	return undef;
}

1;

