#!/usr/bin/perl

package Setup::Inno::Struct2008;

use strict;
use base qw(Setup::Inno::Struct);
use Digest;

sub CheckFile {
	my ($self, $data, $checksum) = @_;
	my $digest = Digest->new('Adler-32');
	$digest->add($data);
	return $digest->digest() eq $checksum;
}

sub Compression0 {
	return 'ZlibBlockReader4008';
}

sub Compression1 {
	return 'ZDecompressor';
}

=comment
procedure CreateFileExtractor;
const
  DecompClasses: array[TSetupCompressMethod] of TCustomDecompressorClass =
    (TStoredDecompressor, TZDecompressor, TBZDecompressor, TLZMA1Decompressor, TLZMA2Decompressor);
begin
  if (Ver>=2008) and (Ver<=4000) then FFileExtractor := TFileExtractor4000.Create(TZDecompressor)
  else FFileExtractor := TFileExtractor.Create(DecompClasses[SetupHeader.CompressMethod]);
  Password := FixPasswordEncoding(Password);  // For proper Unicode/Ansi support
  if SetupHeader.EncryptionUsed and (Password<>'') and not TestPassword(Password) then
    writeln('Warning: incorrect password');
  FFileExtractor.CryptKey:=Password;
end;

See Extract4000.pas
=cut
sub FileReader {
	my ($self, $reader) = @_;
	# TODO
	return undef;
}

1;

