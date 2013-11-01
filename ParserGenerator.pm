use strict;
use feature 'switch';
use Carp;

sub ParserGenerator::unit::types {
	my $self = shift;
	return $self->[2]->types;
}

sub ParserGenerator::list::types {
	my $self = shift;
	my @ret;
	for my $item (@{$self}) {
		if (ref($item)) {
			my $type = $item->types;
			push(@ret, $type) if defined($type);
		} else {
			push(@ret, $item) if defined($item);
		}
	}
	return \@ret;
}

sub ParserGenerator::defer0::types {
	my $self = shift;
	return ref($self->[0]) ? $self->[0]->types(@_) : $self->[0];
}

sub ParserGenerator::defer1::types {
	my $self = shift;
	return ref($self->[1]) ? $self->[1]->types(@_) : $self->[1];
}

sub ParserGenerator::constant_declaration::types {
	return undef;
}

sub ParserGenerator::typed_constant_declaration::types {
	return undef;
}

sub ParserGenerator::interface_part::types {
	my $self = shift;
	my $declarations = @{$self} > 2 ? $self->[2]->types : $self->[1]->types;
	my @ret;
	for my $declarationlist (@{$declarations}) {
		for my $declaration (@{$declarationlist}) {
			push(@ret, $declaration);
		}
	}
	return \@ret;
}

sub ParserGenerator::type_declaration::types {
	my $self = shift;
	return $self->[0];
}


sub ParserGenerator::unit::findtype {
	my ($self, $type) = @_;
	return $self->[2]->findtype($type);
}

sub ParserGenerator::interface_part::findtype {
	my ($self, $type) = @_;
	return @{$self} > 2 ? $self->[2]->findtype($type) : $self->[1]->findtype($type);
}

sub ParserGenerator::defer0::findtype {
	my $self = shift;
	return ref($self->[0]) ? $self->[0]->findtype(@_) : $self->[0];
}

sub ParserGenerator::defer1::findtype {
	my $self = shift;
	return ref($self->[1]) ? $self->[1]->findtype(@_) : $self->[1];
}

sub ParserGenerator::list::findtype {
	my ($self, $type) = @_;
	for my $item (@{$self}) {
		if (ref($item)) {
			my $parser = $item->findtype($type);
			return $parser if defined($parser);
		} else {
			return $item if defined($item);
		}
	}
	return undef;
}

sub ParserGenerator::constant_declaration::findtype {
	return undef;
}

sub ParserGenerator::typed_constant_declaration::findtype {
	return undef;
}

sub ParserGenerator::type_declaration::findtype {
	my ($self, $type) = @_;
	return $type eq $self->[0] ? $self : undef;
}


sub ParserGenerator::defer0::parserbyfield {
	my $self = shift;
	return ref($self->[0]) ? $self->[0]->parserbyfield(@_) : $self->[0];
}

sub ParserGenerator::defer1::parserbyfield {
	my $self = shift;
	return ref($self->[1]) ? $self->[1]->parserbyfield(@_) : $self->[1];
}

sub ParserGenerator::list::parserbyfield {
	my $self = shift;
	my @ret = map({ ref($_) ? $_->parserbyfield(@_) : $_ } @{$self});
	return \@ret;
}

sub ParserGenerator::type_declaration::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my $parser = $self->[2]->parserbyfield($root, $unicode, $indent ? $indent + 1 : 1);
	my $prefix = "\t" x $indent;
	return join("\n",
		"${prefix}sub $self->[0] {",
		"${prefix}\tmy (\$self, \$reader) = \@_;",
		"${prefix}\tmy \$ret;",
		"${prefix}$parser",
		"${prefix}\treturn \$ret;",
		"${prefix}}",
		""
	) if defined($parser);
	return undef;
}

sub ParserGenerator::structured_type::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	if (@{$self} > 1) {
		return $self->[1]->parserbyfield($root, $unicode, $indent);
	} else {
		#carp("Parsers for unpacked types might not do what you expect. Be wary.");
		return $self->[0]->parserbyfield($root, $unicode, $indent);
	}
}

sub ParserGenerator::record_type::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	if (defined($self->[2])) {
		return ("\t" x $indent) . "\$ret = {\n" . $self->[1]->parserbyfield($root, $unicode, $indent + 1) . "\n" . ("\t" x $indent) . "};";
	} else {
		return ("\t" x $indent) . "# no fields";
	}
}

sub ParserGenerator::field_list::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my @parts;
	for my $part (@{$self}) {
		push(@parts, $part->parserbyfield($root, $unicode, $indent)) if ref($part);
	}
	return join("\n", @parts);
}

sub ParserGenerator::fixed_part::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my @frags;
	for my $part (@{$self}) {
		my $frag = $part->parserbyfield($root, $unicode, $indent);
		push(@frags, $frag) if defined($frag);
	}
	return join("\n", @frags);
}

sub ParserGenerator::fixed_fragment::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my $parser = $self->[2]->makeparserbyfield($root, $unicode, $indent);
	if (defined($parser)) {
		my @parsers;
		for my $identifier (@{$self->[0]->parserbyfield($root, $unicode, $indent)}) {
			push(@parsers, ("\t" x $indent) . "$identifier => $parser,");
		}
		return join("\n", @parsers);
	}
	return undef;
}

sub ParserGenerator::enumerated_type::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return ("\t" x $indent) . "\$ret = " . $self->makeparserbyfield($root, $unicode, $indent) . ";";
}

sub ParserGenerator::pointer_type::parserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return ("\t" x $indent) . "\$ret = " . $self->makeparserbyfield($root, $unicode, $indent) . ";";
}


sub ParserGenerator::set_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return "\$reader->ReadSet(" . $self->[2]->setparserbyfield($root, $unicode, $indent) . ")";
}

sub ParserGenerator::enumerated_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return "\$reader->ReadEnum([ " . join(', ', map({ "'$_'" } @{$self->[1]->setparserbyfield($root, $unicode, $indent)})) . " ])";
}

sub ParserGenerator::pointer_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return "\$reader->ReadLongInt(undef and 'pointer to $self->[1]->[0]')";
}

sub ParserGenerator::defer0::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	if (ref($self->[0])) {
		return $self->[0]->makeparserbyfield($root, $unicode, $indent);
	} else {
		given ($self->[0]) {
			when (/^Byte$/i) {
				return "\$reader->ReadByte()";
			}
			when (/^ShortInt$/i) {
				return "\$reader->ReadShortInt()";
			}
			when (/^Word$/i) {
				return "\$reader->ReadWord()";
			}
			when (/^SmallInt$/i) {
				return "\$reader->ReadSmallInt()";
			}
			when (/^LongWord$/i) {
				return "\$reader->ReadLongWord()";
			}
			when (/^Cardinal$/i) {
				return "\$reader->ReadCardinal()";
			}
			when (/^LongInt$/i) {
				return "\$reader->ReadLongInt()";
			}
			when (/^Integer$/i) {
				return "\$reader->ReadInteger()";
			}
			when (/^Int64$|^Integer64$/i) {
				return "\$reader->ReadInt64()";
			}
			when (/^Single$/i) {
				return "\$reader->ReadSingle()";
			}
			when (/^Currency$/i) {
				return "\$reader->ReadCurrency()";
			}
			when (/^Double$/i) {
				return "\$reader->ReadDouble()";
			}
			when (/^Extended$/i) {
				return "\$reader->ReadExtended()";
			}
			when (/^AnsiString$/i) {
				return "\$reader->ReadAnsiString()";
			}
			when (/^WideString$/i) {
				return "\$reader->ReadWideString()";
			}
			when (/^String$/i) {
				return "\$reader->ReadString(" . ($unicode ? 2 : 1 ) . ")";
			}
			when (/^TSHA1Digest$/) {
				return "\$reader->ReadByteArray(20)";
			}
			when (/^TMD5Digest$/) {
				return "\$reader->ReadByteArray(16)";
			}
			when (/^ByteBool$|^Boolean$/i) {
				return "\$reader->ReadByte()";
			}
			when (/^WordBool$/i) {
				return "\$reader->ReadWord()";
			}
			when (/^LongBool$/i) {
				return "\$reader->ReadLongWord()";
			}
			default {
				#warn("Need to fetch type information of $self->[0] for terminal");
				my $subtype = $root->findtype($self->[0]);
				if (defined($subtype)) {
					return $subtype->makeparserbyfield($root, $unicode, $indent);
				} else {
					warn("Type $self->[0] not found, generating call to external parser");
					return "\$self->$self->[0](\$reader)";
				}
			}
		}
	}
}

sub ParserGenerator::structured_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return @{$self} > 1 ? $self->[1]->makeparserbyfield($root, $unicode, $indent) : $self->[0]->makeparserbyfield($root, $unicode, $indent);
}

sub ParserGenerator::type_declaration::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return $self->[2]->makeparserbyfield($root, $unicode, $indent);
}

sub ParserGenerator::record_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	if (defined($self->[2])) {
		return "{\n" . $self->[1]->makeparserbyfield($root, $unicode, $indent + 1) . "\n" . ("\t" x $indent) . "}";
	} else {
		return "{ }";
	}
}

sub ParserGenerator::field_list::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my @parts;
	for my $part (@{$self}) {
		push(@parts, $part->makeparserbyfield($root, $unicode, $indent)) if ref($part);
	}
	return join("\n", @parts);
}

sub ParserGenerator::fixed_part::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my @frags;
	for my $part (@{$self}) {
		my $frag = $part->makeparserbyfield($root, $unicode, $indent);
		push(@frags, $frag) if defined($frag);
	}
	return join("\n", @frags);
}

sub ParserGenerator::fixed_fragment::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my $parser = $self->[2]->makeparserbyfield($root, $unicode, $indent);
	if (defined($parser)) {
		my @parsers;
		for my $identifier (@{$self->[0]->parserbyfield($root, $unicode, $indent)}) {
			push(@parsers, ("\t" x $indent) . "$identifier => $parser,");
		}
		return join("\n", @parsers);
	}
	return undef;
}

sub ParserGenerator::array_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my $indices = $self->[2]->arrayrange($root, $unicode, $indent);
	croak("Arrays with more than 1 dimension aren't supported") if (@{$indices} > 1);
	my $parser = $self->[5]->makeparserbyfield($root, $unicode, $indent);
	return "[ map({ $parser; } $indices->[0]->[0]..$indices->[0]->[1]) ]";
}


sub ParserGenerator::list::arrayrange {
	my ($self, $root, $unicode, $indent) = @_;
	my @indices = map({ $_->arrayrange($root, $unicode, $indent) } @{$self});
	return \@indices;
}

sub ParserGenerator::defer0::arrayrange {
	my ($self, $root, $unicode, $indent) = @_;
	return ref($self->[0]) ? $self->[0]->arrayrange($root, $unicode, $indent) : $self->[0];
}

sub ParserGenerator::subrange_type::arrayrange {
	my ($self, $root, $unicode, $indent) = @_;
	return [ $self->[0]->arrayrange($root, $unicode, $indent), $self->[2]->arrayrange($root, $unicode, $indent) ];
}

sub ParserGenerator::expression::arrayrange {
	my $self = shift;
	return $self->evaluate(@_);
}

sub ParserGenerator::defer0::evaluate {
	my ($self, $root, $unicode, $indent) = @_;
	return ref($self->[0]) ? $self->[0]->evaluate($self, $root, $unicode, $indent) : $self->[0];
}

sub ParserGenerator::factor::evaluate {
	my ($self, $root, $unicode, $indent) = @_;
	given (scalar(@{$self})) {
		when (1) {
			return $self->[0]->evaluate($root, $unicode, $indent);
		}
		when (2) {
			given ($self->[0]) {
				when (/^Not$/i) {
					return ~$self->[0]->evaluate($root, $unicode, $indent);
				}
				when ('+') {
					return $self->[0]->evaluate($root, $unicode, $indent);
				}
				when ('-') {
					return -$self->[0]->evaluate($root, $unicode, $indent);
				}
				default {
					croak("Unknown expression prefix");
				}
			}
		}
		when (3) {
			return $self->[1]->evaluate($root, $unicode, $indent);
		}
		default {
			croak("Unknown expression sequence, length: " . @{$self});
		}
	}
}

sub ParserGenerator::term::evaluate {
	my ($self, $root, $unicode, $indent) = @_;
	if (@{$self->[0]} > 0) {
		my $sum = $self->[0]->[0]->[0]->evaluate($root, $unicode, $indent);
		for (my $i = 0; $i < @{$self->[0]}; $i++) {
			given ($self->[0]->[$i]->[1]) {
				when ('*') {
					$sum *= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when ('/') {
					$sum /= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^Div$/i) {
					$sum = int($sum / $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent));
				}
				when (/^Mod$/i) {
					$sum %= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^And$/i) {
					$sum &= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^Shr$/i) {
					$sum <<= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^Shl$/i) {
					$sum >>= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^As$/i) {
					carp("Type cast operator not supported");
				}
			}
		}
		return $sum;
	} else {
		return $self->[1]->evaluate($root, $unicode, $indent);
	}
}

sub ParserGenerator::simple_expression::evaluate {
	my ($self, $root, $unicode, $indent) = @_;
	if (@{$self->[0]} > 0) {
		my $sum = $self->[0]->[0]->[0]->evaluate($root, $unicode, $indent);
		for (my $i = 0; $i < @{$self->[0]}; $i++) {
			given ($self->[0]->[$i]->[1]) {
				when ('+') {
					$sum += $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when ('-') {
					$sum -= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^Or$/i) {
					$sum |= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^Xor$/i) {
					$sum ^= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
			}
		}
		return $sum;
	} else {
		return $self->[1]->evaluate($root, $unicode, $indent);
	}
}

sub ParserGenerator::expression::evaluate {
	my ($self, $root, $unicode, $indent) = @_;
	if (@{$self} > 1) {
		given ($self->[1]->[0]) {
			when ('<') {
				return $self->[0]->evaluate($root, $unicode, $indent) < $self->[1]->[1]->evaluate($root, $unicode, $indent);
			}
			when ('<=') {
				return $self->[0]->evaluate($root, $unicode, $indent) <= $self->[1]->[1]->evaluate($root, $unicode, $indent);
			}
			when ('>') {
				return $self->[0]->evaluate($root, $unicode, $indent) > $self->[1]->[1]->evaluate($root, $unicode, $indent);
			}
			when ('>=') {
				return $self->[0]->evaluate($root, $unicode, $indent) >= $self->[1]->[1]->evaluate($root, $unicode, $indent);
			}
			when ('=') {
				return $self->[0]->evaluate($root, $unicode, $indent) == $self->[1]->[1]->evaluate($root, $unicode, $indent);
			}
			when ('<>') {
				return $self->[0]->evaluate($root, $unicode, $indent) != $self->[1]->[1]->evaluate($root, $unicode, $indent);
			}
			when (/^In$/i) {
				croak("Range comparison operator not supported");
			}
			when (/^Is$/i) {
				return $self->[0]->evaluate($root, $unicode, $indent) eq $self->[1]->[1]->evaluate($root, $unicode, $indent);
			}
		}
	} else {
		return $self->[0]->evaluate($root, $unicode, $indent);
	}
}


sub ParserGenerator::defer0::setparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	if (ref($self->[0])) {
		return $self->[0]->setparserbyfield($root, $unicode, $indent);
	} else {
		given ($self->[0]) {
			when (/^Byte$|^ShortInt$|^AnsiChar$/i) {
				return "256";
			}
			when (/^Word$|^SmallInt$|^WideChar$/i) {
				return "65536";
			}
			when (/^LongWord$|^Cardinal$|^LongInt$|^Integer$/i) {
				return "4294967296";
			}
			when (/^Int64$/i) {
				return "18446744073709551616";
			}
			when (/^Char$/i) {
				return $unicode ? "65536" : "256";
			}
			default {
				my $subtype = $root->findtype($self->[0]);
				if (defined($subtype)) {
					return $subtype->setparserbyfield($root, $unicode, $indent);
				} else {
					croak("Can't construct set over $self->[0], type not found");
				}
			}
		}
	}
}

sub ParserGenerator::enumerated_type::setparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return "[ " . join(', ', map({ "'$_'" } @{$self->[1]->setparserbyfield($root, $unicode, $indent)})) . " ]";
}

sub ParserGenerator::list::setparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	my @list;
	for my $item (@{$self}) {
		if (ref($item)) {
			my $parser = $item->makeparserbyfield($root, $unicode, $indent);
			push(@list, $parser) if defined($parser);
		} else {
			push(@list, $item) if defined($item);
		}
	}
	return \@list;
}

sub ParserGenerator::type_declaration::setparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return $self->[2]->setparserbyfield($root, $unicode, $indent);
}


####################################################################################################


sub ParserGenerator::list::byfield {
	my $self = shift;
	my @ret;
	for my $item (@{$self}) {
		if (ref($item)) {
			push(@ret, $item->byfield);
		} else {
			push(@ret, $item);
		}
	}
	return \@ret;
}

sub ParserGenerator::empty::byfield {
	my $self = shift;
	return [ ];
}

sub ParserGenerator::defer0::byfield {
	my $self = shift;
	if (ref($self->[0])) {
		return $self->[0]->byfield;
	} else {
		return $self->[0];
	}
}

sub ParserGenerator::defer1::byfield {
	my $self = shift;
	if (ref($self->[1])) {
		return $self->[1]->byfield;
	} else {
		return $self->[1];
	}
}

sub ParserGenerator::unit::byfield {
	my $self = shift;
	return $self->[2]->byfield;
}

sub ParserGenerator::interface_part::byfield {
	my $self = shift;
	my $declarations;
	if (@{$self} > 2) {
		$declarations = $self->[2];
	} else {
		$declarations = $self->[1];
	}
	my $output;
	for my $declarationlist (@{$declarations}) {
		for my $declaration (@{$declarationlist}) {
			use Data::Dumper;
			$output .= Dumper($declaration->byfield);
		}
	}
	return $output;
}

sub ParserGenerator::constant_declaration::byfield {
	my $self = shift;
	return {
		type => 'const',
		name => $self->[0],
		definition => $self->[2]->byfield,
	};
}

sub ParserGenerator::typed_constant_declaration::byfield {
	my $self = shift;
	return {
		type => 'typedconst',
		name => $self->[0],
		subtype => $self->[2]->byfield,
		definition => $self->[4]->byfield,
	};
}

sub ParserGenerator::type_declaration::byfield {
	my $self = shift;
	return {
		type => 'type',
		name => $self->[0],
		definition => $self->[2]->byfield,
	};
}

sub ParserGenerator::expression::byfield {
	my $self = shift;
	if (@{$self} > 1) {
		return {
			first => $self->[0]->byfield,
			operator => $self->[1]->[0],
			second => $self->[1]->[1]->byfield,
		};
	} else {
		return $self->[0]->byfield;
	}
}

sub ParserGenerator::simple_expression::byfield {
	my $self = shift;
	my @ops;
	for my $term (@{$self->[0]}) {
		push(@ops, $term->[0]->byfield);
		push(@ops, $term->[1]);
	}
	push(@ops, $self->[1]->byfield);
	if (@ops > 1) {
		return \@ops;
	} else {
		return $ops[0];
	}
}

sub ParserGenerator::term::byfield {
	my $self = shift;
	my @ops;
	for my $term (@{$self->[0]}) {
		push(@ops, $term->[0]->byfield);
		push(@ops, $term->[1]);
	}
	push(@ops, $self->[1]->byfield);
	if (@ops > 1) {
		return \@ops;
	} else {
		return $ops[0];
	}
}

sub ParserGenerator::factor::byfield {
	my $self = shift;
	if (@{$self} == 1) {
		return $self->[0]->byfield;
	} elsif (@{$self} == 2) {
		if ($self->[0] eq 'not') {
			return [ 'not', $self->[1]->byfield ];
		} elsif ($self->[0] eq '+') {
			return [ $self->[1]->byfield ];
		} elsif ($self->[0] eq '-') {
			return [ 'neg', $self->[1]->byfield ];
		}
	} elsif (@{$self} == 3) {
		return $self->[1]->byfield;
	}
	return undef;
}

sub ParserGenerator::structured_type::byfield {
	my $self = shift;
	if (@{$self} > 1) {
		my $ret = $self->[1]->byfield;
		$ret->{packed} = 1;
		return $ret;
	} else {
		return $self->[0]->byfield;
	}
}

sub ParserGenerator::array_type::byfield {
	my $self = shift;
	return {
		type => 'array',
		indices => $self->[2]->byfield,
		subtype => $self->[5]->byfield,
	};
}

sub ParserGenerator::subrange_type::byfield {
	my $self = shift;
	return {
		type => 'range',
		start => $self->[0]->byfield,
		end => $self->[2]->byfield,
	};
}

sub ParserGenerator::field_list::byfield {
	my $self = shift;
	my $fixed = $self->[0]->byfield;
	my $variant = undef;
	if (ref($fixed) eq 'HASH') {
		$variant = $fixed;
		$fixed = undef;
	}
	if (@{$self} > 2) {
		$variant = $self->[2]->byfield;
	}
	return {
		fixed => $fixed,
		variant => $variant,
	};
}

sub ParserGenerator::fixed_part::byfield {
	my $self = shift;
	my @ret;
	for my $part (@{$self}) {
		my $frag = $part->byfield;
		for my $ident (@{$frag->{identifiers}}) {
			if (ref($frag->{type})) {
				push(@ret, {
					name => $ident,
					%{$frag->{type}},
				});
			} else {
				push(@ret, {
					name => $ident,
					type => $frag->{type},
				});
			}
		}
	}
	return \@ret;
}

sub ParserGenerator::fixed_fragment::byfield {
	my $self = shift;
	return {
		identifiers => $self->[0]->byfield,
		type => $self->[2]->byfield,
	};
}

sub ParserGenerator::enumerated_type::byfield {
	my $self = shift;
	return {
		type => 'enum',
		symbols => $self->[1]->byfield,
	};
}

sub ParserGenerator::set_type::byfield {
	my $self = shift;
	return {
		type => 'set',
		subtype => $self->[2]->byfield,
	};
}

sub ParserGenerator::pointer_type::byfield {
	my $self = shift;
	if (@{$self} > 1) {
		return {
			type => 'pointer',
			base => $self->[1]->byfield,
		};
	} else {
		return {
			type => 'pointer',
			base => 'Char',
		};
	}
}

sub ParserGenerator::character_string::byfield {
	my $self = shift;
	my $string = '';
	for my $sub (@{$self}) {
		if ($sub =~ /^'(.*)'$/) {
			$string .= $1;
		} elsif ($sub =~ /^#\$([0-9a-fA-F]+)$/) {
			$string .= chr(hex($1));
		} elsif ($sub =~ /^#([0-9]+)$/) {
			$string .= chr($1);
		} else {
			$string .= $sub;
		}
	}
	return $string;
}

sub ParserGenerator::string_type::byfield {
	my $self = shift;
	if (defined($self->[1])) {
		return {
			type => 'string',
			subtype => $self->[0],
			length => $self->[1],
		};
	} else {
		return {
			type => 'string',
			subtype => $self->[0],
		};
	}
}

# <record type> ::= 'record' <field list> 'end' | 'record' 'end'
sub ParserGenerator::record_type::byfield {
	my $self = shift;
	if (defined($self->[2])) {
		return {
			type => 'struct',
			records => $self->[1]->byfield,
		};
	} else {
		return {
			type => 'struct',
			records => [ ],
		};
	}
}

1;