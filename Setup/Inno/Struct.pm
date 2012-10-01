#!/usr/bin/perl

package Setup::Inno::Struct;

use strict;
use feature 'switch';
use Setup::Inno::FieldReader;

use constant {
	SetupLdrOffsetTableID => {
		# These are byte strings
		'2008' => "rDlPtS02\x{87}\x{65}\x{56}\x{78}", # 2.0.0.8 until 3.0.0.8
		'4000' => "rDlPtS04\x{87}\x{65}\x{56}\x{78}", # 4.0.0.0 until 4.0.0.2
		'4003' => "rDlPtS05\x{87}\x{65}\x{56}\x{78}", # 4.0.0.3 until 4.0.0.9
		'4010' => "rDlPtS06\x{87}\x{65}\x{56}\x{78}", # 4.0.1.0 until 4.1.0.5
		'4106' => "rDlPtS07\x{87}\x{65}\x{56}\x{78}", # 4.1.0.6 until 5.1.0.2
		'5105' => "rDlPtS\x{cd}\x{e6}\x{d7}\x{7b}\x{0b}\x{2a}", # 5.1.0.5 until 5.4.0.2
	},
};

sub new {
	my ($class, $setupid) = @_;
	given ($setupid) {
		when (SetupLdrOffsetTableID->{'2008'}) {
			require 'Setup/Inno/Struct2008.pm';
			return bless({ }, 'Setup::Inno::Struct2008');
		}
		when (SetupLdrOffsetTableID->{'4000'}) {
			require 'Setup/Inno/Struct4000.pm';
			return bless({ }, 'Setup::Inno::Struct4000');
		}
		when (SetupLdrOffsetTableID->{'4003'}) {
			require 'Setup/Inno/Struct4003.pm';
			return bless({ }, 'Setup::Inno::Struct4003');
		}
		when (SetupLdrOffsetTableID->{'4010'}) {
			require 'Setup/Inno/Struct5105.pm';
			return bless({ }, 'Setup::Inno::Struct5105');
		}
		when (SetupLdrOffsetTableID->{'4106'}) {
			require 'Setup/Inno/Struct4106.pm';
			return bless({ }, 'Setup::Inno::Struct4106');
		}
		when (SetupLdrOffsetTableID->{'5105'}) {
			require 'Setup/Inno/Struct5105.pm';
			return bless({ }, 'Setup::Inno::Struct5105');
		}
		default {
			die("Unknown offset table format, not Inno Setup?");
		}
	}
	return undef;
}

# Override this method if your class name does not follow the usual scheme
sub Version {
	my ($self) = @_;
	if (ref($self) =~ /^Setup::Inno::Struct([0-9]{4}u?)$/) {
		return $1;
	}
	return '0000';
}

# Check the header CRC.
# The default implementation returns 1, for headers without CRC
# Arguments:
#   A string containing header data (must be truncated to the proper length)
#   The checksum to compare against
sub CheckCrc {
	return 1;
}

# Check a decompressed file's checksum.
# The default implementation returns 1, for formats without file checksum.
# Implement the correct checksum algorithm for each version.
# Arguments:
#   A string containing the file's data
#   The checksum to compare against
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

# Compression used for setup.0, for informational purposes
# Subclasses override FieldReader to implement compression
sub Compression0 { return undef; }

# Compression used for files
# Return undef if no compression is used/supported ('Stored' type)
# Arguments:
#   The setup.0 header
sub Compression1 { return undef; }

# Deoptimize executables (the transformation helps with compression)
# Arguments:
#   The optimized executable data
#   The address offset (optional, 0 assumed)
sub TransformCallInstructions {
	my ($self, $data) = @_;
	return $data;
}

sub ReBlessWithVersionString {
	my ($self, $verstr) = @_;
	if ($verstr =~ /\(([0-9])\.([0-9])\.([0-9])([0-9])?(u)?\)/) {
		my $version = "$1$2";
		$version .= defined($4) ? "$3$4" : "0$3";
		$version .= defined($5) ? 'u' : '';
		require "Setup/Inno/Struct$version.pm";
		bless($self, "Setup::Inno::Struct$version");
		return $version;
	}
	return '0000';
}

# Create a field reader from a file handle
# The default implementation does not use compression and reads Delphi objects
# as they are stored in memory.
# Arguments:
#   A file handle serving data to the reader
sub FieldReader {
	my ($self, $input) = @_;
	return Setup::Inno::FieldReader->new($input);
}

# Read a file
# The default implementation returns undef
# Arguments:
#   A file handle serving setup.1 data
#   The setup.0 header
#   The file location data
#   The decryption password (ignored if not encrypted)
sub ReadFile { return undef; }

# Read the setup BMPs and compression DLL
# Not supported before version 4000
# Arguments:
#   A FieldReader
#   A boolean specifying if the compression DLL should be read (use $struct->Compression1($header) to check)
sub SetupBinaries { return undef; }

# Read the various setup.0 data blocks
# Arguments:
#   A FieldReader
#   The number of records to read (except for SetupHeader, it has only one)
sub SetupHeader { return undef; }
sub SetupLanguages { return undef; }
sub SetupCustomMessages { return undef; }
sub SetupPermissions { return undef; }
sub SetupTypes { return undef; }
sub SetupComponents { return undef; }
sub SetupTasks { return undef; }
sub SetupDirs { return undef; }
sub SetupFiles { return undef; }
sub SetupIcons { return undef; }
sub SetupIniEntries { return undef; }
sub SetupRegistryEntries { return undef; }
sub SetupDelete { return undef; }
sub SetupRun { return undef; }
sub SetupFileLocations { return undef; }

1;

