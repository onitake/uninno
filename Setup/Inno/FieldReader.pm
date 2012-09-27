#!/usr/bin/perl

package Setup::Inno::Set;

use strict;
use overload '""' => \&describe;

sub new {
	my ($class, $data) = @_;
	my @self = unpack('C', $data);
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

package Setup::Inno::FieldReader;

use strict;
use Encode;
use POSIX qw(ceil);

sub new {
	my ($class, $reader) = @_;
	return bless({ Reader => $reader }, $class);
}

sub reader {
	return shift()->{Reader};
}

# Reads a Latin-1 (or binary) string
sub ReadString {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 4) || die("Can't read string length");
	my ($length) = unpack('L<', $buffer);
	($self->{Reader}->read($buffer, $length) == $length) || die("Can't read string");
	return $buffer;
}

# Reads a UTF-16 string
sub ReadWideString {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 4) || die("Can't read string length");
	my ($length) = unpack('L<', $buffer);
	($self->{Reader}->read($buffer, $length * 2) == $length * 2) || die("Can't read string");
	return decode('UTF-16LE', $buffer);
}

# Reads a Delphi set of ...
# Sets are represented in Delphi as bit fields, with the highest possible
# value determining the number of bits required.
# Arguments:
#   The number of choices (bits) in the set
# Return:
#   Set object, supporting get(bit #) and set(bit #, value) methods
# Example:
#   Bitfield : set of Char;
#   The maximum value for Char is 255, so 256 bits are required, corresponding to 32 bytes.
sub ReadSet {
	my ($self, $bits) = @_;
	my $bytes = ceil($bits / 8);
	$self->{Reader}->read(my $buffer, $bytes) || die("Can't read set");
	return Setup::Inno::Set->new($buffer);
}

# Reads a Delphi Enum
# The storage required for Enums depends on the number of enumeration values.
# Arguments:
#   The number of enumerated values
sub ReadEnum {
	my ($self, $values) = @_;
	if ($values - 1 <= 255) {
		return $self->ReadByte();
	} elsif ($values - 1 <= 65535) {
		return $self->ReadWord();
	} elsif ($values - 1 <= 4294967295) {
		return $self->ReadLongWord();
	} else {
		return $self->ReadInt64();
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
	$self->{Reader}->read(my $buffer, $length) || die("Can't read byte array");
	return $buffer;
}

sub ReadShortInt {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 1) || die("Can't read byte");
	return unpack('c', $buffer);
}

sub ReadByte {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 1) || die("Can't read byte");
	return unpack('C', $buffer);
}

sub ReadSmallInt {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 2) || die("Can't read word");
	return unpack('s<', $buffer);
}

sub ReadWord {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 2) || die("Can't read word");
	return unpack('S<', $buffer);
}

sub ReadLongInt {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 4) || die("Can't read longword");
	return unpack('l<', $buffer);
}

sub ReadLongWord {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 4) || die("Can't read longword");
	return unpack('L<', $buffer);
}

sub ReadSingle {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 4) || die("Can't read float");
	return unpack('f<', $buffer);
}

sub ReadDouble {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 8) || die("Can't read double");
	return unpack('d<', $buffer);
}

sub ReadInt64 {
	my ($self) = @_;
	$self->{Reader}->read(my $buffer, 8) || die("Can't read quadword");
	return unpack('q<', $buffer);
}

*ReadBoolean = \&ReadByte;
*ReadCardinal = \&ReadLongWord;
*ReadInteger = \&ReadLongInt;
*ReadInteger64 = \&ReadInt64;

1;

