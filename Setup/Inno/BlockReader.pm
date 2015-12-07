package Setup::Inno::BlockReader;

use strict;
use Switch 'Perl6';
use Fcntl;
use Symbol ();
use Digest;
use Carp;

sub open {
	my ($self, $handle, $offset, $blocksize) = @_;
	return $self->new(@_) unless ref($self);

	$handle->seek($offset, Fcntl::SEEK_SET) if defined($offset);
	$blocksize = 4096 unless defined $blocksize;
	
	$handle->read(my $buffer, 9) || croak("Can't read compression header");
	my ($headercrc, $storedsize, $compressed) = unpack('(L2c)<', $buffer);
	my $crc = Digest->new('CRC-32');
	$crc->add(substr($buffer, 4, 5));
	my $digest = $crc->digest;
	#print(STDERR "Header CRC: file=$headercrc calculated=$digest\n");
	($digest == $headercrc) || croak("Invalid CRC in compression header");
	
	$handle->read(my $indata, $storedsize);
	
	my $framesize = $blocksize + 4;
	my $base = $handle->tell;
	my %fields = (
		Handle => $handle,
		BlockSize => $blocksize,
		Compressed => $compressed,
		StoredSize => $storedsize,
		Base => $base,
		Position => 0,
		Crc => $crc->new,
	);
	@{*$self}{keys %fields} = values %fields;
	
	my $pid = open(my $pipe, "-|");
	if (!defined($pid)) {
		croak("Can't fork streamer");
	} elsif ($pid == 0) {
		#$handle->sysseek($base, Fcntl::SEEK_SET);
		my ($funnel, $uncomppid);
		if ($compressed) {
			local $SIG{PIPE} = sub {
				print(STDERR "Exiting due to SIGPIPE\n");
				exit(1);
			};
			$uncomppid = open($funnel, "|-");
			if (!defined($uncomppid)) {
				print(STDERR "Can't fork unpacker\n");
				exit(2);
			} elsif ($uncomppid == 0) {
				my $compheader;
				if (sysread(STDIN, $compheader, 5) != 5) {
					print(STDERR "Can't read LZMA header\n");
					exit(4);
				};
				my ($lclppb, $dictsize) = unpack('(CL)<', $compheader);
				my $pb = int($lclppb / 45);
				my $lclp = $lclppb - $pb * 45;
				my $lp = int($lclp / 9);
				my $lc = $lclp - $lp * 9;
				#print(STDERR "lc=$lc,lp=$lp,pb=$pb,dict=$dictsize\n");
				if (!exec("xz --stdout --decompress --format=raw --lzma1=lc=$lc,lp=$lp,pb=$pb,dict=$dictsize")) {
					print(STDERR "Can't execute xz utility\n");
					exit(5);
				}
			}
		} else {
			$funnel = \*STDOUT;
		}

		my ($offset, $bytes) = (0, 0);
		do {
			#print(STDERR time() . ": Reading\n");
			$bytes = $framesize < $storedsize - $offset ? $framesize : $storedsize - $offset;
			if ($bytes > 4) {
				my $blockcrc = unpack('L<', substr($indata, $offset, 4));
				my $data = substr($indata, $offset + 4, $bytes - 4);
				$crc->add($data);
				if ($crc->digest != $blockcrc) {
					printf(STDERR "Invalid CRC in block\n");
					exit(3);
				}
				$crc->new;
				$funnel->syswrite($data);
			}
			$offset += $bytes;
		} while ($bytes > 0 && $offset < $storedsize);
		$funnel->close;
		waitpid($uncomppid, 0) if defined($uncomppid);
		exit(0);
	} else {
		*$self->{Pipe} = $pipe;
	}
	#$handle->seek($storedsize, Fcntl::SEEK_CUR);
}

sub read {
	my $self = shift;
	my $bytes = *$self->{Pipe}->read(@_);
	*$self->{Position} += $bytes;
	return $bytes;
}

sub tell {
	my $self = shift;
	return *$self->{Position};
}

sub eof {
	my $self = shift;
	return *$self->{Pipe}->eof;
}

sub seek {
	my $self = shift;
	my ($pos, $whence);
	given ($whence) {
		when (Fcntl::SEEK_SET) {
			if ($pos >= *$self->{Position}) {
				$self->read($self->{Pipe}, $pos - *$self->{Position});
				return 1;
			}
		}
		when (Fcntl::SEEK_CUR) {
			if ($pos >= 0) {
				$self->read($self->{Pipe}, $pos);
				return 1;
			}
		}
		when (Fcntl::SEEK_END) {
			warn("SEEK_END not implemented");
		}
	}
	return 0;
}

sub new {
	my $class = shift;
	my $self = bless(Symbol::gensym(), ref($class) || $class);
	tie(*$self, $self);
	$self->open(@_);
	return $self;
}

sub TIEHANDLE {
	return $_[0] if ref($_[0]);
	my $class = shift;
	my $self = bless(Symbol::gensym(), $class);
	$self->open(@_);
	return $self;
}

sub DESTROY { return; }

sub close {
	my $self = shift;
	undef(*$self->{Handle});
	undef(*$self->{Pipe});
	undef(*$self) if ($] eq "5.008");  # workaround for some bug
	return 1;
}

sub opened {
	my $self = shift;
	return defined(*$self->{Pipe});
}

sub binmode {
	my $self = shift;
	return *$self->{Pipe}->binmode(@_);
}

sub getc {
	my $self = shift;
	if ($self->read(my $buffer, 1)) {
		return $buffer;
	}
	return undef;
}

*sysread = \&read;
*syswrite = \&write;
*GETC   = \&getc;
*READ   = \&read;
*SEEK   = \&seek;
*TELL   = \&tell;
*EOF    = \&eof;
*CLOSE  = \&close;
*BINMODE = \&binmode;

1;
