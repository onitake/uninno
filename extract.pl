#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use Setup::Inno;
use Getopt::Long;
use Text::Glob 'glob_to_regex';
use IO::File;
use File::Basename;
use File::Path 'make_path';
use File::Spec::Functions;

$Text::Glob::strict_wildcard_slash = 0;

my ($mode, $outdir, $strip, $help, $overwriteall) = ('extract', 'app', 0, 0, 0);
GetOptions(
	"h" => \$help,
	"l" => sub { $mode = 'list' },
	"e" => sub { $mode = 'extract'; $strip = 0 },
	"x" => sub { $mode = 'extract'; $strip = 1 },
	"d=s" => \$outdir,
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
	exit(1);
}

my $filename = shift(@ARGV);
my @patterns = @ARGV > 0 ? map({ glob_to_regex($_) } @ARGV) : glob_to_regex('*.*');

my $inno = Setup::Inno->new($filename);

print("Installer version: " . $inno->Version . "\n");
print("Number of files: " . $inno->FileCount . "\n");

if ($mode eq 'list') {
	for (my $i = 0; $i < $inno->FileCount; $i++) {
		my $file = $inno->FileInfo($i);
		if ($file->{Type} eq 'App') {
			printf("%u: %s %s %u %s %s%s\n", $i, $file->{Name}, $file->{Type}, $file->{Size}, $file->{Date}->format_cldr('yyyy-MM-dd HH:mm:ss'), $file->{Compressed} ? 'C' : '', $file->{Encrypted} ? 'E' : '');
		}
	}
} elsif ($mode eq 'extract') {
	for my $i (map({ $inno->FindFiles($_) } @patterns)) {
		my $file = $inno->FileInfo($i);
		if ($file->{Type} eq 'App') {
			eval {
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
					my $data = $inno->ReadFile($i);
					my $output = IO::File->new($name, 'w') || die("Can't create $name: $@");
					print($output $data);
					print("done\n");
				} else {
					print("ignored\n");
				}
			} or do {
				print("ERROR: $@");
			}
		}
	}
}

