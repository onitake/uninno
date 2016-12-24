#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin";
use Cwd;
use Getopt::Long;
use ParserGenerator;
use DelphiGrammar;

my ($help, $git, $issrc, $version, $base, $stdtypes) = (undef, 'git', undef, undef, 'Setup::Inno::Struct', 0);
GetOptions(
	"git=s" => \$git,
	"src=s" => \$issrc,
	"version=s" => \$version,
	"base=s" => \$base,
	"stdtypes" => \$stdtypes,
	"help" => \$help,
);
if ($help || !defined($issrc) || !defined($version)) {
	print STDERR "Usage: makestruct.pl --src <issrc> --version <1.2.3[u]> [--parser <makeparser.pl>] [--git <git>] [--base <class>] [--help]\n";
	print STDERR "       issrc      the path to a clone of the innosetup source repository\n";
	print STDERR "       version    the version number to check out prior to parsing (with u suffix for unicode mode)\n";
	print STDERR "       git        the path to the git program (default: $git)\n";
	print STDERR "       base       the name of the base class (default to $base)\n";
	print STDERR "       stdtypes   add parsers for some standard Delphi types (like HKEY or DWORD)\n";
	print STDERR "       help       for this help text\n";
	exit 0;
}

my @types = qw(
	TSetupHeader
	TSetupLanguageEntry
	TSetupCustomMessageEntry
	TSetupPermissionEntry
	TSetupTypeEntry
	TSetupComponentEntry
	TSetupTaskEntry
	TSetupDirEntry
	TSetupFileEntry
	TSetupIconEntry
	TSetupIniEntry
	TSetupRegistryEntry
	TSetupDeleteEntry
	TSetupRunEntry
	TSetupFileLocationEntry
);

my ($major, $minor, $micro, $unicode) = ($version =~ /^([0-9])\.([0-9])\.([0-9]{1,2})(u?)/);
my $tag = sprintf('is-%u_%u_%u', $major, $minor, $micro);
my $module = sprintf('Struct%u%u%02u%s', $major, $minor, $micro, $unicode ? 'u' : '');
my $output = "$module.pm";
my $package = "Setup::Inno::$module";
my $input = $issrc . '/Projects/Struct.pas';

sub checkout {
	my $dir = cwd();
	chdir($issrc);
	system($git, 'checkout', $tag) == 0 || die("Can't check out tag $tag");
	chdir($dir);
}

sub preprocess {
	my ($data) = @_;
	if ($unicode) {
		$$data =~ s/{\$IFDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$1/gs;
		$$data =~ s/{\$IFNDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$3/gs;
	} else {
		$$data =~ s/{\$IFNDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$1/gs;
		$$data =~ s/{\$IFDEF UNICODE}(.*?)({\$ELSE}(.*?))?{\$ENDIF}/$3/gs;
	}
	$$data =~ s#//[^\n]*\n#\n#gs;
}

sub generate {
	my ($out, $data, @types) = @_;
	
	my $re = DelphiGrammar->R('::array', 'ParserGenerator');
	$re->read(\$data) || die("Error parsing input: $$");
	my $value = ${$re->value};

	for my $typename (@types) {
		my $type = $value->findtype($typename);
		if (defined($type)) {
			print($out $type->parserbyfield($value, $unicode));
		} else {
			warn("Type $typename not found, ignoring");
		}
	}
}

print("Checking out tag $tag...\n");
checkout();

print("Reading $input...\n");
open(my $in, '<', $input);
my $data = do { local $/; <$in> } or die;
undef($in);

print("Preprocessing...\n");
preprocess(\$data);

print("Writing to $output...\n");
open(my $out, '>', $output);

print("Writing header...\n");
print($out "package $package;\n");
print($out "use strict;\n");
print($out "use base '$base';\n");

if ($stdtypes) {
print $out <<EOF;
sub TFileTime {
	my (\$self) = \@_;
	my \$tlow = \$self->ReadLongWord();
	my \$thigh = \$self->ReadLongWord();
	my \$hnsecs = \$tlow | (\$thigh << 32);
	my \$secs = int(\$hnsecs / 10000000);
	my \$nsecs = (\$hnsecs - \$secs * 10000000) * 100;
	return DateTime->new(year => 1601, month => 1, day => 1, hour => 0, minute => 0, second => 0, nanosecond => 0)->add(seconds => \$secs, nanoseconds => \$nsecs);
}
sub HKEY {
	return shift->ReadLongWord();
}
sub DWORD {
	return shift->ReadLongWord();
}
sub TSHA1Digest {
	return shift->ReadByteArray(20);
}
sub TMD5Digest {
	return shift->ReadByteArray(16);
}
EOF
}

print("Generating parser for " . join(', ', @types) . "...\n");
generate($out, $data, @types);
print($out "1;\n");
