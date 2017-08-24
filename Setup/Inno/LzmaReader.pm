#!/usr/bin/perl

package Setup::Inno::LzmaReader;

use strict;
require 5.006_000;
use Carp;
use Compress::Raw::Lzma;

our $CHUNK_SIZE = 4096;

sub new {
	my ($class, $reader, $size, $arch) = @_;
	
	# Read and dissect header
	$reader->read(my $header, 5) || croak("Can't read LZMA header");
	my ($lclppb, $dictsize) = unpack('(CL)<', $header);
	my $pb = int($lclppb / 45);
	my $lclp = $lclppb - $pb * 45;
	my $lp = int($lclp / 9);
	my $lc = $lclp - $lp * 9;
	if (defined($arch)) {
		carp("Jump transform not supported");
	}
	
	# Read all data into memory
	my $data;
	if (defined($size)) {
		# Subtract header first
		$size -= 5;
		# Consume as much as we're allowed to
		my $rdbytes = $reader->read($data, $size);
		($rdbytes == $size) || croak("Didn't get all data from stream (expected $size, got $rdbytes)");
	} else {
		# Consume everything the input gives us
		while (!$reader->eof()) {
			$reader->read(my $buffer, $CHUNK_SIZE) || croak("Can't read from stream");
			$data .= $buffer;
		}
	}
	
	# Create a buffer decoder
	my ($decoder, $status) = Compress::Raw::Lzma::RawDecoder->new(Filter => [Lzma::Filter::Lzma1(DictSize => $dictsize, Lc => $lc, Lp => $lp, Pb => $pb)]);
	if (!defined($decoder)) {
		croak("Can't create LZMA decoder: " . $status);
	}
	
	# Uncompress data into memory
	$status = $decoder->code($data, my $uncompressed);
	if ($status != LZMA_OK && $status != LZMA_STREAM_END) {
		croak("Error uncompressing data: " . $status);
	}
	
	return IO::File->new(\$uncompressed, 'r') || croak("Can't create file handle for uncompressed data: $!");
}


package Setup::Inno::Lzma2Reader;

use strict;
require 5.006_000;
use Carp;
use Compress::Raw::Lzma;
use IO::Scalar;

our $CHUNK_SIZE = 4096;

sub new {
	my ($class, $reader, $size, $arch) = @_;

	# Read and dissect header
	$reader->read(my $header, 1) || croak("Can't read LZMA2 header");
	my ($dictsizeflag) = unpack('C', $header);
	my $dictsize;
	if ($dictsizeflag > 40) {
		croak("Invalid dictionary size: $dictsizeflag");
	} elsif ($dictsizeflag == 40) {
		$dictsize = 0xffffffff;
	} elsif ($dictsizeflag & 1) {
		$dictsize = 3 * (1 << (($dictsizeflag - 1) / 2 + 11));
	} else {
		$dictsize = 1 << ($dictsizeflag / 2 + 12);
	}
	if (defined($arch)) {
		carp("Jump transform not supported");
	}
	
	# Read all data into memory
	my $data;
	if (defined($size)) {
		# Subtract header first
		$size -= 1;
		# Consume as much as we're allowed to
		my $rdbytes = $reader->read($data, $size);
		($rdbytes == $size) || croak("Didn't get all data from stream (expected $size, got $rdbytes)");
	} else {
		# Consume everything the input gives us
		while (!$reader->eof()) {
			$reader->read(my $buffer, $CHUNK_SIZE) || croak("Can't read from stream");
			$data .= $buffer;
		}
	}
	
	# Create a buffer decoder
	my ($decoder, $status) = Compress::Raw::Lzma::RawDecoder->new(Filter => [Lzma::Filter::Lzma2(DictSize => $dictsize)]);
	if (!defined($decoder)) {
		croak("Can't create LZMA2 decoder: " . $status);
	}
	
	# Uncompress data into memory
	$status = $decoder->code($data, my $uncompressed);
	if ($status != LZMA_OK && $status != LZMA_STREAM_END) {
		croak("Error uncompressing data: " . $status);
	}
	
	return IO::File->new(\$uncompressed, 'r') || croak("Can't create file handle for uncompressed data: $!");
}


1;
