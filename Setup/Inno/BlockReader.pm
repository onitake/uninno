package Setup::Inno::BlockReader;

use strict;
require 5.006_000;
use Digest;
use Carp;
use Setup::Inno::LzmaReader;

sub new {
	my ($class, $handle, $offset, $blocksize) = @_;

	$handle->seek($offset, Fcntl::SEEK_SET) if defined($offset);
	$blocksize = 4096 unless defined $blocksize;
	
	$handle->read(my $buffer, 9) || croak("Can't read compression header");
	my ($headercrc, $storedsize, $compressed) = unpack('(L2c)<', $buffer);
	my $crc = Digest->new('CRC-32');
	# CRC32 digest includes data length value and compressed flag
	$crc->add(substr($buffer, 4, 5));
	my $digest = $crc->digest;
	($digest == $headercrc) || croak("Invalid CRC in compression header");
	
	my $framesize = $blocksize + 4;
	my ($offset, $bytes, $compressedsize, $packed) = (0, 0, 0, '');
	do {
		$bytes = $framesize < $storedsize - $offset ? $framesize : $storedsize - $offset;
		if ($bytes >= 4) {
			$handle->read(my $indata, $bytes);
			my $blockcrc = unpack('L<', substr($indata, 0, 4));
			my $data = substr($indata, 4, $bytes - 4);
			$crc->new;
			$crc->add($data);
			if ($crc->digest != $blockcrc) {
				croak("Invalid CRC in block");
			}
			$packed .= $data;
			$offset += $bytes;
			$compressedsize += $bytes - 4;
		}
	} while ($bytes > 0 && $offset < $storedsize);
	
	$handle = IO::File->new(\$packed, 'r') || croak("Can't create file handle for packed data: $!");
	
	if ($compressed) {
		$handle = Setup::Inno::LzmaReader->new($handle, $compressedsize);
	}
	return $handle;
}

1;
