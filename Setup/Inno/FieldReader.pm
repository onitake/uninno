#!/usr/bin/perl

package Setup::Inno::Set;

use strict;
use overload '""' => \&describe;

sub new {
	my ($class, $data) = @_;
	my @self = unpack('C*', $data);
	return bless(\@self, $class);
}

sub get {
	my ($self, $bit) = @_;
	return ($self->[$bit >> 3] >> ($bit & 0x7)) & 1;
}

sub set {
	my ($self, $bit, $value) = @_;
	if ($value) {
		$self->[$bit >> 3] |= (1 << ($bit & 0x7));
	} else {
		$self->[$bit >> 3] &= ~(1 << ($bit & 0x7));
	}
}

sub describe {
	my ($self) = @_;
	return unpack('B*', join('', @{$self}));
}

sub match {
	my ($self, $fields) = @_;
	my $ret = { };
	for (my $i = 0; $i < @{$fields}; $i++) {
		$ret->{$fields->[$i]} = $self->get($i);
	}
	return $ret;
}

package Setup::Inno::FieldReader;

use strict;
use Encode;
use POSIX qw(ceil);

sub new {
	my ($class, $reader, $debug) = @_;
	return bless({ Reader => $reader, Debug => $debug }, $class);
}

sub reader {
	return shift()->{Reader};
}

sub read {
	return shift()->{Reader}->read(@_);
}

sub tell {
	return shift()->{Reader}->tell(@_);
}

sub seek {
	return shift()->{Reader}->seek(@_);
}

sub close {
	return shift()->{Reader}->close(@_);
}

# Reads a string, the type is determined by the first argument
# Arguments:
#   The type of string
#     0 or undefined: Binary string (no conversion)
#     1: 8-bit string, using Windows codepage 1252
#     2: Unicode string, using UTF-16
#   The string length in bytes (only for fixed length strings)
sub ReadString {
	my ($self, $coding, $length) = @_;
	if (!defined($length)) {
		warn("Reading 4 bytes from " . $self->{Reader}->tell) if $self->{Debug};
		# Note that the length is the number of bytes, not characters
		$self->{Reader}->read(my $buffer, 4) || die("Can't read string length");
		($length) = unpack('L<', $buffer);
	}
	warn("Reading $length bytes from " . $self->{Reader}->tell) if $self->{Debug};
	($self->{Reader}->read(my $buffer, $length) == $length) || die("Can't read string");
	if ($coding) {
		if ($coding == 1) {
			return decode('cp1252', $buffer);
		} elsif ($coding == 2) {
			return decode('UTF-16LE', $buffer);
		}
	} else {
		return $buffer;
	}
}

# Reads a CP-1252 (Windows Latin) string
# Arguments:
#   The string length (if fixed size, optional)
sub ReadAnsiString {
	my ($self, $length) = @_;
	return $self->ReadString(1, $length);
}

# Reads a UTF-16 string (actually UCS-2, but that was a bad design decision on Microsoft's side)
# Arguments:
#   The string length (if fixed size, optional)
sub ReadWideString {
	my ($self, $length) = @_;
	return $self->ReadString(2, $length);
}

# Reads a Delphi set of ...
# Sets are represented in Delphi as bit fields, with the highest possible
# value determining the number of bits required.
# Arguments:
#   The number of choices (bits) in the set
#   or
#   An arrayref of field names
# Return:
#   Set object, supporting get(bit #) and set(bit #, value) methods
#   or (if fields names given)
#   A hashref containing <field name> => <value> pairs
# Example:
#   Bitfield : set of Char;
#   The maximum value for Char is 255, so 256 bits are required, corresponding to 32 bytes.
sub ReadSet {
	my ($self, $fields) = @_;
	my $bits;
	if (ref($fields) eq 'ARRAY') {
		$bits = @{$fields};
	} else {
		$bits = $fields;
	}
	my $bytes = ceil($bits / 8);
	warn("Reading $bytes bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, $bytes) || die("Can't read set");
	my $set = Setup::Inno::Set->new($buffer);
	if (ref($fields) eq 'ARRAY') {
		return $set->match($fields);
	} else {
		return $set;
	}
}

# Reads a Delphi Enum
# The storage required for Enums depends on the number of enumeration values.
# Arguments:
#   The number of enumerated values (choices)
#   or
#   An arrayref of enumerated names
# Return:
#   The enumerated value
#   or (if names were given)
#   The enumerated name
sub ReadEnum {
	my ($self, $names) = @_;
	my $values;
	if (ref($names) eq 'ARRAY') {
		$values = @{$names};
	} else {
		$values = $names;
	}
	my $value;
	if ($values - 1 <= 255) {
		warn("Reading 1 byte") if $self->{Debug};
		$value = $self->ReadByte();
	} elsif ($values - 1 <= 65535) {
		warn("Reading 2 bytes") if $self->{Debug};
		$value = $self->ReadWord();
	} elsif ($values - 1 <= 4294967295) {
		warn("Reading 4 bytes") if $self->{Debug};
		$value = $self->ReadLongWord();
	} else {
		warn("Reading 8 bytes") if $self->{Debug};
		$value = $self->ReadInt64();
	}
	if (ref($names) eq 'ARRAY') {
		return $names->[$value];
	} else {
		return $value;
	}
}

=comment
 Type  Storage size                        Range            
 
 Byte       1                             0 to 255
 ShortInt   1                          -127 to 127
 Word       2                             0 to 65,535
 SmallInt   2                       -32,768 to 32,767
 LongWord   4                             0 to 4,294,967,295
 Cardinal   4*                            0 to 4,294,967,295
 LongInt    4                -2,147,483,648 to 2,147,483,647
 Integer    4*               -2,147,483,648 to 2,147,483,647
 Int64      8    -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
 
 Single     4     7  significant digits, exponent   -38 to +38
 Currency   8    50+ significant digits, fixed 4 decimal places
 Double     8    15  significant digits, exponent  -308 to +308
 Extended  10    19  significant digits, exponent -4932 to +4932
 
 * Note : the Integer and Cardinal types are both 4 bytes in size at present (Delphi release 7), but are not guaranteed to be this size in the future. All other type sizes are guaranteed.
=cut
 
sub ReadByteArray {
	my ($self, $length) = @_;
	warn("Reading $length bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, $length) || die("Can't read byte array");
	return $buffer;
}

sub ReadShortInt {
	my ($self) = @_;
	warn("Reading 1 byte") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 1) || die("Can't read byte");
	return unpack('c', $buffer);
}

sub ReadByte {
	my ($self) = @_;
	warn("Reading 1 byte") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 1) || die("Can't read byte");
	return unpack('C', $buffer);
}

sub ReadSmallInt {
	my ($self) = @_;
	warn("Reading 2 bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 2) || die("Can't read word");
	return unpack('s<', $buffer);
}

sub ReadWord {
	my ($self) = @_;
	warn("Reading 2 bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 2) || die("Can't read word");
	return unpack('S<', $buffer);
}

sub ReadLongInt {
	my ($self) = @_;
	warn("Reading 4 bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 4) || die("Can't read longword");
	return unpack('l<', $buffer);
}

sub ReadLongWord {
	my ($self) = @_;
	warn("Reading 4 bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 4) || die("Can't read longword");
	return unpack('L<', $buffer);
}

sub ReadSingle {
	my ($self) = @_;
	warn("Reading 4 bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 4) || die("Can't read float");
	return unpack('f<', $buffer);
}

sub ReadDouble {
	my ($self) = @_;
	warn("Reading 8 bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 8) || die("Can't read double");
	return unpack('d<', $buffer);
}

sub ReadInt64 {
	my ($self) = @_;
	warn("Reading 8 bytes") if $self->{Debug};
	$self->{Reader}->read(my $buffer, 8) || die("Can't read quadword");
	return unpack('q<', $buffer);
}

*ReadBoolean = \&ReadByte;
*ReadCardinal = \&ReadLongWord;
*ReadInteger = \&ReadLongInt;
*ReadInteger64 = \&ReadInt64;

1;

