#!/usr/bin/perl

package Setup::Inno::LzmaReader4;

use strict;
use base qw(IO::Handle);
#use UnCompress::UnLzma;


package Setup::Inno::LzmaReader;

use strict;
use base qw(IO::File);
use File::Temp;
use Carp;

sub new {
	my ($class, $reader, $size, $arch) = @_;

	# Read and dissect header
	$reader->read(my $header, 5) || croak("Can't read LZMA header");
	my ($lclppb, $dictsize) = unpack('(CL)<', $header);
	my $pb = int($lclppb / 45);
	my $lclp = $lclppb - $pb * 45;
	my $lp = int($lclp / 9);
	my $lc = $lclp - $lp * 9;
	my $transform;
	if (defined($arch) && $arch ne '') {
		if ($arch =~ /^(x86|powerpc|ia64|arm|armthumb|sparc)$/i) {
			$transform = '--' . lc($0);
		} else {
			croak("Invalid architecture for jump transform: $arch");
		}
	} else {
		$transform = '';
	}
	
	# Create temporary file and consume data
	# Note that automatic file removal is disabled as this can cause problems (early deletion etc.)
	my $temp = File::Temp->new(UNLINK => 0) || croak("Can't create temp file");
	if (defined($size)) {
		# Subtract header first
		$size -= 5;
		# Consume as much as we're allowed to
		while ($size) {
			my $length = ($size > 4096) ? 4096 : $size;
			my $rdbytes = $reader->read(my $buffer, $length);
			($rdbytes == $length) || croak("Didn't get all data from stream (expected $length, got $rdbytes)");
			$size -= $rdbytes;
			$temp->write($buffer) || croak("Can't write to temp file");
		}
	} else {
		# Consume everything the input gives us
		while (!$reader->eof()) {
			$reader->read(my $buffer, 4096) || croak("Can't read from stream");
			$temp->write($buffer) || croak("Can't write to temp file");
		}
	}
	my $tempfile = $temp->filename();
	#$temp->close();
	
	# Spawn subprocess for decompression
	my $self = $class->SUPER::new("xz --stdout --decompress --format=raw --lzma1=lc=$lc,lp=$lp,pb=$pb,dict=$dictsize $transform $tempfile |") || croak("Can't open decompressor");

	# Store temp file name, this should work on IO::Handle type objects
	*$self->{LzmaReaderTempFile} = $tempfile;

	# Rebless file handle so we can override methods
	return bless($self, $class);
}

# And all this hackery so we can make sure the temp file gets destroyed at the right time...
sub DESTROY {
	my $self = shift;
	unlink(*$self->{LzmaReaderTempFile}) || carp("Can't delete temporary file");
	$self->SUPER::DESTROY(@_);
}

package Setup::Inno::Lzma2Reader;

use strict;
use Carp;

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
	my $transform;
	if (defined($arch) && $arch ne '') {
		if ($arch =~ /^(x86|powerpc|ia64|arm|armthumb|sparc)$/i) {
			$transform = '--' . lc($0);
		} else {
			croak("Invalid architecture for jump transform: $arch");
		}
	} else {
		$transform = '';
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
			$reader->read(my $buffer, 4096) || croak("Can't read from stream");
			$data .= $buffer;
		}
	}
	
	# Spawn a subprocess to feed the data to xz
	my $pid = open(my $pipe, "-|");
	if (!defined($pid)) {
		croak("Can't fork streamer");
	} elsif ($pid == 0) {
		local $SIG{PIPE} = sub {
			#print(STDERR "Exiting due to SIGPIPE\n");
			exit(1);
		};
		my $uncomppid = open(my $funnel, "|-");
		if (!defined($uncomppid)) {
			print(STDERR "Can't fork unpacker\n");
			exit(2);
		} elsif ($uncomppid == 0) {
			if (!exec("xz --stdout --decompress --format=raw --lzma2=dict=$dictsize $transform")) {
				print(STDERR "Can't execute xz utility\n");
				exit(5);
			}
		}
		
		# Write the whole buffer into the pipe
		$funnel->write($data);
		
		# Close and wait for completion
		$funnel->close();
		waitpid($uncomppid, 0) if defined($uncomppid);
		exit(0);
	}

	return $pipe;
}

package Setup::Inno::LzmaReader3;

use strict;
use base qw(IO::Handle);
use IO::File;

sub new {
	my ($class, $reader, $size) = @_;

	# Read and dissect header
	$reader->read(my $header, 5) || die("Can't read LZMA header");
	my ($lclppb, $dictsize) = unpack('(CL)<', $header);
	my $pb = int($lclppb / 45);
	my $lclp = $lclppb - $pb * 45;
	my $lp = int($lclp / 9);
	my $lc = $lclp - $lp * 9;

	# Fork subprocess for decompression
	my $pidi = open(my $fdi, "-|");
	if (!defined($pidi)) {
		die("Can't fork decompression feeder");
	} elsif ($pidi == 0) {
		# Child; fork and pipe data to xz
		#print(STDERR "xz --stdout --decompress --format=raw --lzma1=lc=$lc,lp=$lp,pb=$pb,dict=$dictsize\n");
		my $pido = open(my $fdo, "|xz --stdout --decompress --format=raw --lzma1=lc=$lc,lp=$lp,pb=$pb,dict=$dictsize");
		if (!defined($pido)) {
			die("Can't fork xz decompressor");
		}
		my $xz = IO::Handle->new_from_fd($fdo, 'w');
		local $SIG{PIPE} = sub {
			print(STDERR "Exiting due to SIGPIPE\n");
			exit(0);
		};
		my $rdbytes = 4096;
		while ($rdbytes && !$reader->eof()) {
			print(STDERR "Reading 4096 bytes\n");
			$rdbytes = $reader->read(my $buffer, 4096) || die("Can't read from stream");
			if ($rdbytes) {
				print(STDERR "Writing " . length($buffer) . " bytes\n");
				#use Data::Hexdumper;
				#print(STDERR hexdump($buffer));
				$xz->write($buffer) || die("Can't write to decompressor");
			}
		}
		# Close output and exit
		print(STDERR "Exiting at end of input\n");
		$xz->close();
		waitpid($pido, 0);
		exit(0);
	} else {
		# Parent; return handle
		print(STDERR "Returning stdout from xz subprocess $pidi\n");
		my $input = IO::Handle->new_from_fd($fdi, 'r');
		#$input->read(my $buffer, 128);
		#use Data::Hexdumper;
		#print(STDERR hexdump($buffer));
		return bless($input, $class);
	}
}

sub read {
	my $self = shift;
	my ($buffer, $length, $offset) = @_;
	print(STDERR "Reading $length bytes from xz\n");
	$self->SUPER::read(@_);
}

sub seek {
	my $self = shift;
	my ($pos, $whence) = @_;
	print(STDERR "Seeking to $pos in xz, mode $whence\n");
	$self->SUPER::seek(@_);
}

package Setup::Inno::LzmaReader2;

use strict;
use IO::Handle;
use IO::File;

sub new {
	my ($class, $reader, $size) = @_;

	# Read and dissect header
	$reader->read(my $header, 5) || die("Can't read LZMA header");
	my ($lclppb, $dictsize) = unpack('(CL)<', $header);
	my $pb = int($lclppb / 45);
	my $lclp = $lclppb - $pb * 45;
	my $lp = int($lclp / 9);
	my $lc = $lclp - $lp * 9;

	# Fork subprocess for decompression
	my $pid = open(my $fd, "-|");
	if (!defined($pid)) {
		die("Can't fork");
	} elsif ($pid == 0) {
		sleep(1);
		my $xzpid = open(my $xz, "|xz --stdout --decompress --format=raw --lzma1=lc=$lc,lp=$lp,pb=$pb,dict=$dictsize") || die("Can't fork unpacker");
		local $SIG{PIPE} = sub {
			print(STDERR "Exiting due to SIGPIPE\n");
			exit(0);
		};
		my $bytes;
		do {
			#print(STDERR "Reading\n");
			$bytes = sysread($reader, my $buffer, 4096);
			if ($bytes > 0) {
				#print(STDERR "Streaming $bytes bytes\n");
				syswrite($xz, $buffer);
			}
		} while ($bytes > 0);
		print(STDERR "Exiting due to end of data eof=" . eof($reader) . " bytes=$bytes\n");
		close($xz);
		waitpid($xzpid, 0);
		exit(0);
	} else {
		return IO::Handle->new_from_fd($fd, '<') || die("Can't create reader handle for pipe");
	}
}

1;
