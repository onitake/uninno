#!/usr/bin/perl

package Setup::Inno::LzmaReader;

use strict;
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
			if (!exec("xz --stdout --decompress --format=raw --lzma1=lc=$lc,lp=$lp,pb=$pb,dict=$dictsize $transform")) {
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


1;
