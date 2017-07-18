#!/usr/bin/perl

package Setup::Inno::Interpret;

use strict;
use Switch 'Perl6';
use Carp;
use Setup::Inno::FieldReader;

our $SetupLdrOffsetTableID = {
    # These are byte strings
    '2008' => "rDlPtS02\x{87}\x{65}\x{56}\x{78}", # 2.0.8 until 3.0.8
    '4000' => "rDlPtS04\x{87}\x{65}\x{56}\x{78}", # 4.0.0 until 4.0.2
    '4003' => "rDlPtS05\x{87}\x{65}\x{56}\x{78}", # 4.0.3 until 4.0.9
    '4010' => "rDlPtS06\x{87}\x{65}\x{56}\x{78}", # 4.0.10 until 4.1.5
    '4106' => "rDlPtS07\x{87}\x{65}\x{56}\x{78}", # 4.1.6 until 5.1.2
    '5105' => "rDlPtS\x{cd}\x{e6}\x{d7}\x{7b}\x{0b}\x{2a}", # from 5.1.5
};
our $InterpreterVersions = [
    2008,
    4000,
    4003,
    4010,
    4106,
    5105,
    5309,
];

sub new {
	my ($class, $setupid) = @_;
	given ($setupid) {
		when ($SetupLdrOffsetTableID->{'2008'}) {
			require 'Setup/Inno/Interpret2008.pm';
			return bless({ Version => '2008' }, 'Setup::Inno::Interpret2008');
		}
		when ($SetupLdrOffsetTableID->{'4000'}) {
			require 'Setup/Inno/Interpret4000.pm';
			return bless({ Version => '4000' }, 'Setup::Inno::Interpret4000');
		}
		when ($SetupLdrOffsetTableID->{'4003'}) {
			require 'Setup/Inno/Interpret4003.pm';
			return bless({ Version => '4003' }, 'Setup::Inno::Interpret4003');
		}
		when ($SetupLdrOffsetTableID->{'4010'}) {
			require 'Setup/Inno/Interpret4010.pm';
			return bless({ Version => '4010' }, 'Setup::Inno::Interpret4010');
		}
		when ($SetupLdrOffsetTableID->{'4106'}) {
			require 'Setup/Inno/Interpret4106.pm';
			return bless({ Version => '4106' }, 'Setup::Inno::Interpret4106');
		}
		when ($SetupLdrOffsetTableID->{'5105'}) {
			require 'Setup/Inno/Interpret5105.pm';
			return bless({ Version => '5105' }, 'Setup::Inno::Interpret5105');
		}
	}
	croak("Unknown offset table format, not Inno Setup?");
}

# Returns the InnoSetup version this interpreter instance can handle.
# The version is only precise if ReBless has been called.
# Returns just the setup header version otherwise.
# Override this method if your class name does not follow the usual scheme
sub Version {
	return shift->{Version};
	#my ($self) = @_;
	#if (ref($self) =~ /^Setup::Inno::Interpret([0-9]{4}u?)$/) {
	#	return $1;
	#}
	#return '0000';
}

# Check a decompressed file's checksum.
# The default implementation returns 1, for formats without file checksum.
# Implement the correct checksum algorithm for each version.
# Arguments:
#   A string containing the file's data
#   The file location entry
sub CheckFile {
	return 1;
}

sub OffsetTableSize {
	# All offset tables contain at least the 12 byte ID, override if you need more
	return 12;
}

sub ParseOffsetTable {
	# No-op
}

# Compression used for files
# Returns undef if no compression is used/supported ('Stored' type)
# Arguments:
#   The setup.0 header
sub Compression1 { return undef; }

# Deoptimize executables (the transformation helps with compression)
# Arguments:
#   The optimized executable data
#   The address offset (optional, 0 assumed)
sub TransformCallInstructions {
	my ($self, $data, $offset) = @_;
	return $data;
}

# Change the blessing of $self to the closest available package according to a version string.
# In other words, parse the version string and sweep over the available version-specific interpreter
# classes until one is found that can handle data for this InnoSetup version.
# Also stores the exact version, so an appropriate structure reader can be created later,
# Arguments:
#   The InnoSetup version string
sub ReBless {
	my ($self, $verstr) = @_;
	if ($verstr =~ /\(([0-9])\.([0-9])\.([0-9])([0-9])?([a-z])?\)(\s*\(([a-z])?\))?/) {
		my $bareversion = "$1$2";
		$bareversion .= defined($4) ? "$3$4" : "0$3";
		$self->{IsUnicode} = ((defined($5) && $5 eq 'u') || (defined($7) && $7 eq 'u') ? 'u' : '');
		my $version = $bareversion . $self->{IsUnicode};
		$self->{Version} = $version;
		my ($low, $high) = (0, $#{$InterpreterVersions});
		my $found;
		if ($bareversion >= $InterpreterVersions->[$high]) {
			# above or equal max
			$found = $InterpreterVersions->[$high];
		} elsif ($bareversion < $InterpreterVersions->[$low]) {
			# below min
			$high = $low;
		}
		while (!defined($found) && $low < $high) {
			my $mid = int(($low + $high) / 2);
			if ($bareversion >= $InterpreterVersions->[$mid]) {
				# above or equal mid (and below high)
				if ($bareversion < $InterpreterVersions->[$mid + 1]) {
					$found = $InterpreterVersions->[$mid];
				} else {
					$low = $mid;
				}
			} else {
				# below mid (and above or equal low)
				$high = $mid;
			}
		}
		if (defined($found)) {
			require "Setup/Inno/Interpret$found.pm";
			my $class = "Setup::Inno::Interpret$found";
			bless($self, $class);
		} else {
			die("Internal error: Interpreter class not found for $bareversion");
		}
	} elsif ($verstr =~ /My Inno Setup Extensions Setup Data \(3.0.6.[12]\)/) {
		# Martijn Laan's extensions, unsupported for now
		# Bless/return '3008' here and implement Interpret30008.pm once you support them
		croak("Unsupported version: $verstr");
	} else {
		croak("Unsupported version: $verstr");
	}
}

# Create a structure reader for setup.0 data.
# You should only call this method if you have assigned the exact version with ReBless().
# Uses FieldReader() to construct a suitable reader (handling decompression etc.).
# Arguments:
#   A file handle pointing to setup.0 data
sub StructReader {
	my ($self, $reader) = @_;
	my $version = $self->{Version};
	require "Setup/Inno/Struct$version.pm";
	my $class = "Setup::Inno::Struct$version";
	return $class->new($self->FieldReader($reader));
}

# Create a field reader from a file handle
# The default implementation does not use compression and reads Delphi objects
# as they are stored in memory.
# Arguments:
#   A file handle serving data to the reader
#   An offset from the start of the file, or undef if no seeking is necessary
sub FieldReader {
	my ($self, $input) = @_;
	return Setup::Inno::FieldReader->new($input);
}

# Fetch information about setup.bin files, for multi-disk installers
# Arguments:
#   The filename of the setup executable
#   The Setup0 header
sub DiskInfo { return undef; }

# Read a file
# The default implementation returns undef
# Arguments:
#   A file handle serving setup.1 data
#   The setup.0 header
#   The file location data
#   The start offset of setup.1 data
#   The decryption password (ignored if not encrypted)
#   An list of slice records occupied by this file (including the first, optional)
sub ReadFile { return undef; }

# Read the setup BMPs and compression DLL
# Not supported before version 4000
# Arguments:
#   A FieldReader
#   A boolean specifying if the compression DLL should be read (use $struct->Compression1($header) to check)
sub SetupBinaries { return undef; }

# Read the various setup.0 data blocks
# Arguments:
#   A structure reader suitable for the setup.0 version
#   The number of records to read (except for SetupHeader, it has only one)
sub SetupHeader {
	my ($self, $struct) = @_;
	return $struct->TSetupHeader();
}

sub SetupLanguages {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupLanguageEntry() } 0..($count - 1) ];
}

sub SetupCustomMessages {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupCustomMessageEntry() } (0..$count - 1) ];
}

sub SetupPermissions {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupPermissionEntry() } (0..$count - 1) ];
}

sub SetupTypes {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupTypeEntry() } (0..$count - 1) ];
}

sub SetupComponents {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupComponentEntry() } (0..$count - 1) ];
}

sub SetupTasks {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupTaskEntry() } (0..$count - 1) ];
}

sub SetupDirs {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupDirEntry() } (0..$count - 1) ];
}

sub SetupFiles {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupFileEntry() } (0..$count - 1) ];
}

sub SetupIcons {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupIconEntry() } (0..$count - 1) ];
}

sub SetupIniEntries {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupIniEntry() } (0..$count - 1) ];
}

sub SetupRegistryEntries {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupRegistryEntry() } (0..$count - 1) ];
}

sub SetupDelete {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupDeleteEntry() } (0..$count - 1) ];
}

sub SetupRun {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupRunEntry() } (0..$count - 1) ];
}

sub SetupFileLocations {
	my ($self, $struct, $count) = @_;
	return [ map { $struct->TSetupFileLocationEntry() } (0..$count - 1) ];
}

# Verifies that a supplied password is correct
# Arguments:
#   The Setup0 header
#   The password
sub VerifyPassword {
	return 1;
}

1;