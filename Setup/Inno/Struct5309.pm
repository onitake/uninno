#!/usr/bin/perl

package Setup::Inno::Struct5309;

use strict;
use base qw(Setup::Inno::Struct5203);
use Digest;

sub CheckFile {
	my ($self, $data, $checksum) = @_;
	my $digest = Digest->new('SHA-1');
	$digest->add($data);
	return $digest->digest() eq $checksum;
}

=comment
procedure TransformCallInstructions5309(var Buf; Size: Integer;
  const Encode: Boolean; const AddrOffset: LongWord);
{ [Version 3] Converts relative addresses in x86/x64 CALL and JMP instructions
  to absolute addresses if Encode is True, or the inverse if Encode is False. }
type
  PByteArray = ^TByteArray;
  TByteArray = array[0..$7FFFFFFE] of Byte;
var
  P: PByteArray;
  I: Integer;
  Addr, Rel: LongWord;
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
        Addr := (AddrOffset + LongWord(I) + 4) and $FFFFFF;  { may wrap, but OK }
        Rel := P[I] or (P[I+1] shl 8) or (P[I+2] shl 16);
        if not Encode then
          Dec(Rel, Addr);
        { For a slightly higher compression ratio, we want the resulting high
          byte to be $00 for both forward and backward jumps. The high byte
          of the original relative address is likely to be the sign extension
          of bit 23, so if bit 23 is set, toggle all bits in the high byte. }
        if Rel and $800000 <> 0 then
          P[I+3] := not P[I+3];
        if Encode then
          Inc(Rel, Addr);
        P[I] := Byte(Rel);
        P[I+1] := Byte(Rel shr 8);
        P[I+2] := Byte(Rel shr 16);
      end;
      Inc(I, 4);
    end
    else
      Inc(I);
  end;
end;
=cut
sub TransformCallInstructions {
	my ($self, $data, $offset) = @_;
	# TODO
	warn("Call instruction deoptimizer not available");
}

1;

