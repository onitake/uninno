#!/usr/bin/perl

use strict;
use Switch 'Perl6';
use Marpa::R2;
use Getopt::Long;
use ParserGenerator;
use DelphiGrammar;

my ($class, $input, $output, $help, $unicode, @classes);
GetOptions(
	"type=s" => \@classes,
	"input=s" => \$input,
	"output=s" => \$output,
	"unicode" => \$unicode, "ansi" => sub { $unicode = 0; },
	"declarations" => sub { undef($class); },
	"help" => \$help
);
if ($help) {
	print STDERR "Usage: makeparser.pl [--input <input.pas>] [--type <TypeName> [--type <TypeName> ...] | --declarations] [--output <output.pm>] [--unicode | --ansi] [--help]\n";
	print STDERR "If no options are given, stdin and stdout are used and the declaration list is printed.\n";
	exit 0;
}
my ($in, $out);
if (defined($input)) {
	open($in, '<', $input) or die;
} else {
	$in = \*STDIN;
}
if (defined($output)) {
	open($out, '>', $output) or die;
} else {
	$out = \*STDOUT;
}

my $re = DelphiGrammar->R('::array', 'Semantics');
my $data = do { local $/; <$in> } or die;

if ($unicode) {
	$data =~ s/{\$IFDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$1/gs;
	$data =~ s/{\$IFNDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$3/gs;
} else {
	$data =~ s/{\$IFNDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$1/gs;
	$data =~ s/{\$IFDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$3/gs;
}

$re->read(\$data) || die("Error parsing input: $$");
my $value = ${$re->value};


$re = DelphiGrammar->R('::array', 'ParserGenerator');
$re->read(\$data) || die("Error parsing input: $$");
$value = ${$re->value};

if (defined($class)) {
	my $type = $value->findtype($class);
	if (defined($type)) {
		print STDERR $type->parserbyfield($value, $unicode);
	} else {
		die("Type $class not found");
	}
} elsif (@classes) {
	for my $class (@classes) {
		my $type = $value->findtype($class);
		if (defined($type)) {
			print $out $type->parserbyfield($value, $unicode);
		} else {
			warn("Type $class not found, ignoring");
		}
	}
} else {
	for my $decl (@{$value->types}) {
		print $out "$decl\n";
	}
}
