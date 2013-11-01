package Setup::Inno::BlockReaderNew;

use strict;
use feature 'switch';
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

package Setup::Inno::BlockReaderOld;

use strict;
use feature 'switch';
use Fcntl;
use Symbol ();
use Carp;

sub open {
	my ($self, $reader, $blocksize) = @_;
	return $self->new(@_) unless ref($self);
	*$self->{Reader} = $reader;
	*$self->{BlockSize} = defined($blocksize) ? $blocksize : 4096;
	*$self->{FrameSize} = 4 + *$self->{BlockSize};
	*$self->{Cache} = '';
	*$self->{CachePosition} = 0;
	*$self->{CacheRemain} = 0;
	*$self->{Reader}->read(my $buffer, 9) || croak("Can't read compression header");
	(*$self->{HdrCrc}, *$self->{StoredSize}, *$self->{Compressed}) = unpack('(L2c)<', $buffer);
	my $crc = Digest->new('CRC-32');
	$crc->add(substr($buffer, 4, 5));
	($crc->digest() == *$self->{HdrCrc}) || croak("Invalid CRC in compression header");
	*$self->{Base} = *$self->{Reader}->tell();
	*$self->{StoredPosition} = 0;
	*$self->{StoredRemain} = *$self->{StoredSize};
	*$self->{DataSize} = int(*$self->{StoredSize} / *$self->{FrameSize}) * *$self->{BlockSize} + *$self->{StoredSize} % *$self->{FrameSize} - 4;
	*$self->{DataPosition} = 0;
	*$self->{DataRemain} = *$self->{DataSize};
}

sub read {
	my $self = shift;
	my $buffer = \shift;
	my ($length, $offset) = @_;
	# Fail-fast if we're not open
	$self->opened() || return 0;
	# Destination string offset
	$offset = 0 if (!defined($offset));
	# Create destination if it doesn't exist
	$$buffer = '' if (!defined($$buffer));
	# Padding or lvalue substr() will fail
	$$buffer .= $offset x '\0' if (length($$buffer) < $offset);
	# Byte read counter
	my $allbytes = 0;
	# Loop until all blocks have been copied
	while ($length > 0) {
		if (*$self->{CacheRemain} == 0) {
			# Refill cache if empty, return if no more data
			$self->refill() || return $allbytes;
		}
		# Number of bytes to transfer for this chunk: all if enough data remains in cache, the remaining data in cache otherwise
		my $rbytes = ($length > *$self->{CacheRemain}) ? *$self->{CacheRemain} : $length;
		#print(join(', ', length($$buffer), $offset + $allbytes, $rbytes, length(*$self->{Cache}), length(*$self->{Cache}) - *$self->{CacheLeft}, $rbytes));
		# Transfer one chunk of data
		substr($$buffer, $offset + $allbytes, $rbytes) = substr(*$self->{Cache}, *$self->{CachePosition}, $rbytes);
		# Update counters
		$allbytes += $rbytes;
		$length -= $rbytes;
		*$self->{CacheRemain} -= $rbytes;
		*$self->{CachePosition} += $rbytes;
		*$self->{DataRemain} -= $rbytes;
		*$self->{DataPosition} += $rbytes;
	}
	return $allbytes;
}

sub seek {
	my ($self, $position, $whence) = @_;
	given ($whence) {
		when (Fcntl::SEEK_SET) {
			# Validate position
			($position >= 0) || return 0;
			($position < *$self->{DataSize}) || return 0;
			# Determine block number
			my $block = int($position / *$self->{BlockSize});
			# Reset cache and update offset counters
			*$self->{CacheRemain} = 0;
			*$self->{StoredPosition} = $block * *$self->{FrameSize};
			*$self->{StoredRemain} = *$self->{StoredSize} - *$self->{StoredPosition};
			# Seek to frame base offset
			*$self->{Reader}->seek(*$self->{Base} + *$self->{StoredPosition}, Fcntl::SEEK_SET) || return 0;
			# Read next chunk
			$self->refill();
			# Update counters
			my $offset = $position % *$self->{BlockSize};
			*$self->{CachePosition} = $offset;
			*$self->{CacheRemain} = *$self->{BlockSize} - *$self->{CachePosition};
			*$self->{DataPosition} = $position;
			*$self->{DataRemain} = *$self->{DataSize} - *$self->{DataPosition};
			return 1;
		}
		when (Fcntl::SEEK_CUR) {
			return $self->seek(*$self->{DataPosition} + $position, Fcntl::SEEK_SET);
		}
		when (Fcntl::SEEK_END) {
			return $self->seek(*$self->{DataSize} + $position, Fcntl::SEEK_SET);
		}
	}
	return 0;
}

sub tell {
	my $self = shift;
	return *$self->{DataPosition};
}

sub eof {
	my $self = shift;
	return *$self->{DataRemain} == 0;
}

sub length {
	my $self = shift;
	return *$self->{DataSize};
}

sub compressed {
	my $self = shift;
	return *$self->{Compressed};
}

sub refill {
	my ($self) = @_;
	# Check if the cache is empty, refuse to refill otherwise
	(*$self->{CacheRemain} == 0) || return 0;
	# Check if we try to read beyond the end
	(*$self->{StoredRemain} > 4) || return 0;
	# Read CRC
	*$self->{Reader}->read(my $buffer, 4) || croak("Can't read block CRC");
	# Update counters
	*$self->{StoredPosition} += 4;
	*$self->{StoredRemain} -= 4;
	my $blockcrc = unpack('L<', $buffer);
	# Is this the last frame?
	my $length = (*$self->{StoredRemain} < *$self->{BlockSize}) ? *$self->{StoredRemain} : *$self->{BlockSize};
	# Read one chunk of data
	*$self->{Reader}->read(*$self->{Cache}, $length) || croak("Can't read data block");
	# Update counters
	*$self->{StoredPosition} += $length;
	*$self->{StoredRemain} -= $length;
	# Check CRC
	my $crc = Digest->new('CRC-32');
	$crc->add(*$self->{Cache});
	($crc->digest() == $blockcrc) || croak("Invalid CRC in compressed data");
	# Update cache counters
	*$self->{CachePosition} = 0;
	*$self->{CacheRemain} = $length;
	return 1;
}

# Behold! Here be IO::String magic

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
	undef(*$self->{Reader});
	undef(*$self) if ($] eq "5.008");  # workaround for some bug
	return 1;
}

sub opened {
	my $self = shift;
	return defined(*$self->{Reader});
}

sub binmode {
	return 1;
}

sub getc {
	my $self = shift;
	if ($self->read(my $buffer, 1)) {
		return $buffer;
	}
	return undef;
}

*sysread = \&read;
*GETC   = \&getc;
*READ   = \&read;
*SEEK   = \&seek;
*TELL   = \&tell;
*EOF    = \&eof;
*CLOSE  = \&close;
*BINMODE = \&binmode;

1;
