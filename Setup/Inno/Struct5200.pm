#!/usr/bin/perl

package Setup::Inno::Struct5200;

use strict;
use base qw(Setup::Inno::Struct5105);

=comment
procedure TransformCallInstructions(var Buf; Size: Integer;
  const Encode: Boolean; const AddrOffset: LongWord);
{ Transforms addresses in relative CALL or JMP instructions to absolute ones
  if Encode is True, or the inverse if Encode is False.
  This transformation can lead to a higher compression ratio when compressing
  32-bit x86 code. }
type
  PByteArray = ^TByteArray;
  TByteArray = array[0..$7FFFFFFE] of Byte;
var
  P: PByteArray;
  I, X: Integer;
  Addr: LongWord;
begin
  if Size < 5 then
    Exit;
  Dec(Size, 4);
  P := @Buf;
  I := 0;
  while I < Size do begin
    { Does it appear to be a CALL or JMP instruction with a relative 32-bit
      address? }
    if (P[I] = $E8) or (P[I] = $E9) then begin
      Inc(I);
      { Verify that the high byte of the address is $00 or $FF. If it isn't,
        then what we've encountered most likely isn't a CALL or JMP. }
      if (P[I+3] = $00) or (P[I+3] = $FF) then begin
        { Change the lower 3 bytes of the address to be relative to the
          beginning of the buffer, instead of to the next instruction. If
          decoding, do the opposite. }
        Addr := AddrOffset + LongWord(I) + 4;  { may wrap, but OK }
        if not Encode then
          Addr := -Addr;
        for X := 0 to 2 do begin
          Inc(Addr, P[I+X]);
          P[I+X] := Byte(Addr);
          Addr := Addr shr 8;
        end;
      end;
      Inc(I, 4);
    end
    else
      Inc(I);
  end;
end;

Length 3727360
Address  00       01      
00090000 fff6a457 ffffa45b
000dfffe 00035edc 00115ede
000ffffd ffefff2e ffffff2f
0010fffd 000a81fe 001b81ff
0017fffe ffe7fb19 fffffb1b
=cut
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
	while ($i < $size) {
		# Does it appear to be a CALL or JMP instruction with a relative 32-bit address?
		my $instr = ord(substr($data, $i, 1));
		if ($instr == 0xe8 || $instr == 0xe9) {
			$i++;
=comment
			# Fetch the original address
			my $old = unpack('L<', substr($data, $i, 4));
			# Verify that the high byte of the address is $00 or $FF. If it isn't, then what we've encountered most likely isn't a CALL or JMP.
			if (($old & 0xff000000) == 0xff || ($old & 0xff000000) == 0x00) {
				# Calculate the address of the next instruction
				my $addr = ($offset + $i + 4) & 0xffffffff;
				# Add/subtract the instruction address from the jump address
				my $new = ($old - $addr) & 0xffffffff;
				# Write the address back
				substr($data, $i, 4) = pack('L<', $new);
				printf("addr:0x%08x old:0x%08x new:0x%08x\n", $addr, $old, $new);
			}
=cut
			# Verify that the high byte of the address is $00 or $FF. If it isn't, then what we've encountered most likely isn't a CALL or JMP.
			my $arg = ord(substr($data, $i + 3, 1));
			if ($arg == 0x00 || $arg == 0xff) {
				# Change the lower 3 bytes of the address to be relative to the beginning of the buffer, instead of to the next instruction. If decoding, do the opposite.
				my $addr = $offset + $i + 4;
				if ($i == 0x90000) {
					my $old = unpack('L', substr($data, $i, 4));
					printf("instr:0x%02x addr:0x%08x old:0x%08x ", $instr, $addr, $old);
				}
				# if (!Encode) {
					$addr = -$addr;
				# }
				# Replace address
				for (my $x = 0; $x <= 2; $x++) {
					$addr += ord(substr($data, $i + $x, 1));
					# Mask our the LSB or we might get a Unicode character...
					substr($data, $i + $x, 1) = chr($addr & 0xff);
					$addr >>= 8;
				}
				if ($i == 0x90000) {
					my $new = unpack('L', substr($data, $i, 4));
					printf("new:0x%08x\n", $new);
				}
			}
			$i += 4;
		} else {
			$i++;
		}
	}
	return $data;
}

1;
