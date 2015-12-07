use strict;
use Switch 'Perl6';
use Carp;
#use Data::Dumper;
#$Data::Dumper::Indent = 1;

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
		"${prefix}\tmy (\$self) = \@_;",
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
	return "\$self->ReadSet(" . $self->[2]->setparserbyfield($root, $unicode, $indent) . ")";
}

sub ParserGenerator::enumerated_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return "\$self->ReadEnum([ " . join(', ', map({ "'$_'" } @{$self->[1]->setparserbyfield($root, $unicode, $indent)})) . " ])";
}

sub ParserGenerator::pointer_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	return "\$self->ReadLongInt(undef and 'pointer to $self->[1]->[0]')";
}

sub ParserGenerator::defer0::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	if (ref($self->[0])) {
		return $self->[0]->makeparserbyfield($root, $unicode, $indent);
	} else {
		#carp("Need to fetch type information of $self->[0] for terminal");
		my $subtype = $root->findtype($self->[0]);
		if (defined($subtype)) {
			return $subtype->makeparserbyfield($root, $unicode, $indent);
		} else {
			warn("Type $self->[0] not found, generating call to external parser");
			return "\$self->$self->[0]()";
		}
	}
}

sub ParserGenerator::string_type::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	given ($self->[0]) {
		when (/^AnsiString$/i) {
			return "\$self->ReadString(1" . (defined($self->[2]) ? (", " . $self->[2] . ")") : ")");
		}
		when (/^WideString$/i) {
			return "\$self->ReadString(2" . (defined($self->[2]) ? (", " . ($self->[2] * 2) . ")") : ")");
		}
		when (/^String/i) {
			return "\$self->ReadString(" . ($unicode ? "2" : "1" ) . (defined($self->[2]) ? (", " . $self->[2] . ")") : ")");
		}
	}
	return undef;
}

sub ParserGenerator::ordinal_type_identifier::makeparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
	given ($self->[0]) {
		when (/^Byte$/i) {
			return "\$self->ReadByte()";
		}
		when (/^ShortInt$/i) {
			return "\$self->ReadShortInt()";
		}
		when (/^Word$/i) {
			return "\$self->ReadWord()";
		}
		when (/^SmallInt$/i) {
			return "\$self->ReadSmallInt()";
		}
		when (/^LongWord$/i) {
			return "\$self->ReadLongWord()";
		}
		when (/^Cardinal$/i) {
			return "\$self->ReadCardinal()";
		}
		when (/^LongInt$/i) {
			return "\$self->ReadLongInt()";
		}
		when (/^Integer$/i) {
			return "\$self->ReadInteger()";
		}
		when (/^Int64$|^Integer64$/i) {
			return "\$self->ReadInt64()";
		}
		when (/^Single$/i) {
			return "\$self->ReadSingle()";
		}
		when (/^Currency$/i) {
			return "\$self->ReadCurrency()";
		}
		when (/^Double$/i) {
			return "\$self->ReadDouble()";
		}
		when (/^Extended$/i) {
			return "\$self->ReadExtended()";
		}
		when (/^AnsiChar$/i) {
			return "\$self->ReadString(1, 1)";
		}
		when (/^WideChar$/i) {
			return "\$self->ReadString(2, 2)";
		}
		when (/^Char$/i) {
			return "\$self->ReadString(" . ($unicode ? "2, 2)" : "1, 1)");
		}
		when (/^ByteBool$|^Boolean$/i) {
			return "\$self->ReadByte()";
		}
		when (/^WordBool$/i) {
			return "\$self->ReadWord()";
		}
		when (/^LongBool$/i) {
			return "\$self->ReadLongWord()";
		}
		default {
			return undef;
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
	#warn Dumper($indices);
	my $type = $self->[5]->makeparserbyfield($root, $unicode, $indent);
	#warn Dumper($type);
	my $parser = $type;
	for my $index (reverse(@{$indices})) {
		my $first;
		my $last;
		if (ref($index)) {
			$first = $index->[0];
			$last = $index->[1];
		} else {
			$first = 0;
			$last = $index - 1;
		}
		if ($first == 0) {
			$parser = "[ map({ $parser } ($first..$last)) ]";
		} else {
			$parser = "{ map({ \$_ => $parser } ($first..$last)) }";
		}
	}
	#warn Dumper($parser);
	return $parser;
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
					carp("Right shift operator not supported");
					#$sum >>= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
				}
				when (/^Shl$/i) {
					carp("Left shift operator not supported");
					#$sum <<= $i < @{$self->[0]} - 1 ? $self->[0]->[$i + 1]->[1]->evaluate($root, $unicode, $indent) : $self->[1]->evaluate($root, $unicode, $indent);
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
		my $subtype = $root->findtype($self->[0]);
		if (defined($subtype)) {
			return $subtype->setparserbyfield($root, $unicode, $indent);
		} else {
			croak("Can't construct set over $self->[0], type not found");
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

sub ParserGenerator::ordinal_type_identifier::setparserbyfield {
	my ($self, $root, $unicode, $indent) = @_;
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
		when (/^Int(eger)?64$/i) {
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

1;
