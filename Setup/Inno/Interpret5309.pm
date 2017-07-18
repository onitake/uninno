#!/usr/bin/perl

package Setup::Inno::Interpret5309;

use strict;
use base qw(Setup::Inno::Interpret5105);
use Encode;

sub TransformCallInstructions {
	my ($self, $data, $offset) = @_;
	if (length($data) < 5) {
		return $data;
	}
	if (!defined($offset)) {
		$offset = 0;
	}
	my $size = length($data) - 4;
	my $i = 0;
	#printf("Transforming %u bytes of binary data from offset 0x%08x\n", length($data) - 4, $offset);
	while ($i < $size) {
		#print("Remaining data: " . ($size - $i) . "\n");
		# Does it appear to be a CALL or JMP instruction with a relative 32-bit address?
		my $instr = ord(substr($data, $i, 1));
		if ($instr == 0xe8 || $instr == 0xe9) {
			$i++;
			# Verify that the high byte of the address is $00 or $FF. If it isn't, then what we've encountered most likely isn't a CALL or JMP.
			my $arg = ord(substr($data, $i + 3, 1));
			if ($arg == 0x00 || $arg == 0xff) {
				# Change the lower 3 bytes of the address to be relative to the beginning of the buffer, instead of to the next instruction. If decoding, do the opposite.
				my $addr = ($offset + $i + 4) & 0xffffff;
				my $rel =  ord(substr($data, $i, 1)) | (ord(substr($data, $i + 1, 1)) << 8) | (ord(substr($data, $i + 2, 1)) << 16);
				$rel -= $addr;
				# Debug
				my $old = unpack('L', substr($data, $i, 4));
				#printf("instr:0x%02x addr:0x%08x rel:0x%08x old:0x%08x ", $instr, $addr, $rel, $old);
				# For a slightly higher compression ratio, we want the resulting high byte to be $00 for both forward and backward jumps. The high byte of the original relative address is likely to be the sign extension of bit 23, so if bit 23 is set, toggle all bits in the high byte.
				if ($rel & 0x800000) {
					substr($data, $i + 3, 1) = chr(~ord(substr($data, $i + 3, 1)) & 0xff);
				}
				substr($data, $i, 1) = chr($rel & 0xff);
				substr($data, $i + 1, 1) = chr(($rel >> 8) & 0xff);
				substr($data, $i + 2, 1) = chr(($rel >> 16) & 0xff);
				# Debug
				my $new = unpack('L', substr($data, $i, 4));
				#printf("new:0x%08x\n", $new);
			}
			$i += 4;
		} else {
			$i++;
		}
	}
	return $data;
}

sub VerifyPassword {
	my ($self, $setup0, $password) = @_;
	if ($setup0->{Options}->{shPassword}) {
		my $digest = Digest->new('SHA-1');
		$digest->add('PasswordCheckHash');
		$digest->add(join('', @{$setup0->{PasswordSalt}}));
		if ($self->{IsUnicode}) {
			$digest->add(encode('UTF-16LE', $password));
		} else {
			$digest->add($password);
		}
		return $digest->digest() eq $setup0->{PasswordHash};
	} else {
		return !defined($password);
	}
}

1;

