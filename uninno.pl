#!/usr/bin/perl

# Set to 1 to enable debugging mode
our $DEBUG = 1;

use strict;
use warnings;
use diagnostics;
if ($DEBUG) {
	enable diagnostics;
} else {
	disable diagnostics;
}

use FindBin;
use lib "$FindBin::Bin";
use Setup::Inno;
use Getopt::Long;
use Text::Glob 'glob_to_regex';
use IO::File;
use File::Basename;
use File::Path 'make_path';
use File::Spec::Functions;

# Enable autoflush on stdout
$| = 1;
# Ignore path separators on glob
$Text::Glob::strict_wildcard_slash = 0;

my ($mode, $outdir, $strip, $help, $overwriteall, $password, $type) = ('extract', 'app', 0, 0, 0, undef, 'app');
GetOptions(
	"h" => \$help,
	"l" => sub { $mode = 'list' },
	"e" => sub { $mode = 'extract'; $strip = 0 },
	"x" => sub { $mode = 'extract'; $strip = 1 },
	"d=s" => \$outdir,
	"p=s" => \$password,
	"t=s" => \$type,
);
if ($help || @ARGV < 1) {
	print(STDERR "Usage: extract.pl [-l | -e | -x] [-h] [-d path] setup.exe [file.ext] [file.*] ...\n");
	print(STDERR "Extracts files from InnoSetup setup.exe installers, loading setup-#.bin slices as appropriate.\n");
	print(STDERR "You may optionally specify filenames or filename patterns to have only matching files extracted.\n");
	print(STDERR "Options:\n");
	print(STDERR "-h  Show this help\n");
	print(STDERR "-l  List files instead of extracting\n");
	print(STDERR "-e  Extract files with full (relative) path (default action)\n");
	print(STDERR "-x  Extract files with stripped path\n");
	print(STDERR "-d  Specify output path (default: ./app/)\n");
	print(STDERR "-p  Specify the decryption password\n");
	print(STDERR "-t  Select which destination type is considered (default: app)\n");
	print(STDERR "    Known destination types: app, tmp, commonappdata, code, uninstexe, regsvrexe\n");
	print(STDERR "    Use 'all' to ignore the type\n");
	exit(1);
}

my $filename = shift(@ARGV);
my @patterns = @ARGV > 0 ? map({ glob_to_regex($_) } @ARGV) : glob_to_regex('*');

my $inno = Setup::Inno->new($filename);

print("Installer version: " . $inno->Version . "\n");
print("Number of files: " . $inno->FileCount . "\n");

if (!$inno->VerifyPassword($password)) {
	print("WARNING: Invalid password specified. Extraction may fail when files are encrypted.\n");
}

sub extract {
	my ($i, $file) = @_;
	printf("%u: %s %s %u %s %s%s...", $i, $file->{Name}, $file->{Type}, $file->{Size}, $file->{Date}->format_cldr('yyyy-MM-dd HH:mm:ss'), $file->{Compressed} ? 'C' : '', $file->{Encrypted} ? 'E' : '');
	my $name = $file->{Name};
	if ($strip) {
		$name =~ s#^.*?([^/]+)$#$1#;
	} else {
		$name =~ s#^[./]*##;
	}
	$name = catfile($outdir, $name);
	my $path = dirname($name);
	if (!stat($path)) {
		make_path($path);
	}
	my $writeone = $overwriteall;
	if (stat($name) && !$writeone) {
		print(" $name exists. Overwrite? [y/N/a]");
		my $response = <STDIN>;
		if ($response =~ /^[yY]/) {
			$writeone = 1;
		} elsif ($response =~ /^[aA]/) {
			$writeone = 1;
			$overwriteall = 1;
		}
	} else {
		$writeone = 1;
	}
	if ($writeone) {
		my $data = $inno->ReadFile($i, $password);
		my $output = IO::File->new($name, 'w') || die("Can't create $name: $@");
		binmode($output);
		print($output $data);
		undef($output);
		print("done\n");
	} else {
		print("ignored\n");
	}
}

if ($mode eq 'list') {
	for (my $i = 0; $i < $inno->FileCount; $i++) {
		my $file = $inno->FileInfo($i);
		if ($type eq 'all' or $file->{Type} eq $type) {
			printf("%u: %s %s %u %s %s%s\n", $i, $file->{Name}, $file->{Type}, $file->{Size}, $file->{Date}->format_cldr('yyyy-MM-dd HH:mm:ss'), $file->{Compressed} ? 'C' : '', $file->{Encrypted} ? 'E' : '');
		}
	}
} elsif ($mode eq 'extract') {
	for my $i (map({ $inno->FindFiles($_) } @patterns)) {
		my $file = $inno->FileInfo($i);
		if (defined($file->{Type})) {
			if ($file->{Type} eq $type) {
				if ($DEBUG) {
					extract($i, $file);
				} else {
					eval {
						extract($i, $file);
					} or do {
						print("ERROR: $@");
					}
				}
			}
		} elsif ($DEBUG) {
			use Data::Dumper;
			print("Unknown file:\n");
			print(Dumper($file));
		}
	}
}

