#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use Setup::Inno;
use Data::Dumper;
use Data::Hexdumper;
use File::Type;
use IO::File;
use File::Basename;

if (@ARGV < 1) {
	print("Usage: extract.pl <setup.exe>\n");
	exit(1);
}

my $filename = $ARGV[0];
my $inno = Setup::Inno->new($filename);

print("Installer version: " . $inno->Version() . "\n");
#print Dumper $inno->FileLocations();
#$inno->Setup0();

mkdir("/tmp/uninno/");
for (my $i = 0; $i < $inno->FileCount(); $i++) {
	my $file = $inno->FileInfo($i);
	if ($file->{Type} eq 'App') {
		printf("%u: %s %s %u %s %s%s\n", $i, $file->{Name}, $file->{Type}, $file->{Size}, $file->{Date}->format_cldr('yyyy-MM-dd HH:mm:ss'), $file->{Compressed} ? 'C' : '', $file->{Encrypted} ? 'E' : '');
		my $data = $inno->ReadFile($i);
		my $path = "/tmp/uninno/" . dirname($file->{Name});
		mkdir($path);
		my $output = IO::File->new("/tmp/uninno/" . $file->{Name}, '>') || die("Can't create " . "/tmp/uninno/" . $file->{Name});
		print($output $data);
	}
}

#my $file = $inno->ReadFile(822);
#print $file;
